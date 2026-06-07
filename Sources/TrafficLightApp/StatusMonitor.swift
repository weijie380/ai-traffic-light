import Cocoa
import Foundation

// MARK: - 状态监控器

/// 轮询 status.json，解析状态并通知视图更新。
class StatusMonitor {

    static let shared = StatusMonitor()

    // MARK: - 回调

    var onStatusChanged: ((TrafficLightState, String?) -> Void)?
    var onDoneStateEntered: ((Int, String?) -> Void)?

    // MARK: - 状态文件路径

    private let statusFileURL: URL = {
        // 优先检查项目目录
        let projectPath = URL(fileURLWithPath: "/Library/code/pycharmcode").appendingPathComponent(AppConstants.projectStatusFileRelativePath)
        if FileManager.default.fileExists(atPath: projectPath.path) {
            return projectPath
        }
        
        // 然后检查用户目录
        let home = FileManager.default.homeDirectoryForCurrentUser
        let userPath = home.appendingPathComponent(AppConstants.statusFileRelativePath)
        if FileManager.default.fileExists(atPath: userPath.path) {
            return userPath
        }
        
        // 默认返回项目目录路径
        return projectPath
    }()

    // MARK: - 内部状态

    private var pollTimer: Timer?
    private var countdownTimer: Timer?
    private var minDisplayTimer: Timer?

    private(set) var currentDisplayState: TrafficLightState = .idle
    private(set) var currentTask: String?
    private(set) var greenRemainingSeconds: TimeInterval = 0
    private(set) var lastTransitionCount: Int = 0

    private var lastHeartbeat: Date = .distantPast
    private var doneStateTimestamp: Date?
    private var lastStateChangeTime: CFTimeInterval = 0
    private var stateBeforePause: TrafficLightState = .idle
    private var fileExisted: Bool = false
    private var readCount: Int = 0

    // MARK: - 暂停状态

    var isPaused: Bool { currentDisplayState == .paused }
    private var pauseStartTime: Date?
    private var lastToggleTime: Date = .distantPast
    private var savedDoneTimestamp: Date?
    private var savedRemainingSeconds: TimeInterval = 0

    // MARK: - 启动/停止

    func start() {
        try? FileManager.default.createDirectory(
            at: statusFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)

        readStatusFile()

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.readStatusFile()
        }
        if let timer = pollTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        pollTimer?.invalidate()
        countdownTimer?.invalidate()
        minDisplayTimer?.invalidate()
    }

    // MARK: - 永久空闲

    func resetToIdle() {
        DispatchQueue.main.async { [weak self] in
            self?.applyState(.idle)
        }
    }

    // MARK: - 暂停/恢复

    func pause() {
        guard !isPaused else { return }
        stateBeforePause = currentDisplayState
        pauseStartTime = Date()
        savedDoneTimestamp = doneStateTimestamp
        savedRemainingSeconds = greenRemainingSeconds

        countdownTimer?.invalidate()
        countdownTimer = nil

        currentDisplayState = .paused
        onStatusChanged?(.paused, currentTask)
    }

    func resume() {
        guard isPaused, let pauseStart = pauseStartTime else { return }
        let pauseDuration = Date().timeIntervalSince(pauseStart)
        pauseStartTime = nil

        // 临时恢复状态以允许 readStatusFile 正常执行
        currentDisplayState = stateBeforePause
        lastTransitionCount = 0
        readStatusFile()

        // 如果恢复时仍在 done 状态，恢复倒计时
        if stateBeforePause == .done,
           let savedTS = savedDoneTimestamp,
           currentDisplayState == .done {
            doneStateTimestamp = savedTS.addingTimeInterval(pauseDuration)
            let dur = TimeInterval(SettingsManager.shared.greenLightDuration)
            greenRemainingSeconds = max(0, dur + doneStateTimestamp!.timeIntervalSinceNow)
            if greenRemainingSeconds > 0 {
                startCountdown()
            } else {
                applyState(.idle)
            }
        }

        savedDoneTimestamp = nil
        savedRemainingSeconds = 0
    }

    func togglePause() {
        guard Date().timeIntervalSince(lastToggleTime) > 0.2 else { return }
        lastToggleTime = Date()
        isPaused ? resume() : pause()
    }

    func recalculateCountdown() {
        guard currentDisplayState == .done, let doneTS = doneStateTimestamp else { return }
        let dur = TimeInterval(SettingsManager.shared.greenLightDuration)
        greenRemainingSeconds = max(0, dur + doneTS.timeIntervalSinceNow)
        if greenRemainingSeconds <= 0 {
            applyState(.idle)
        }
    }

    // MARK: - 文件读取

    private func readStatusFile() {
        readCount += 1
        let url = statusFileURL

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            // 读取文件
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                // 文件不存在或解析失败
                DispatchQueue.main.async {
                    if self.fileExisted {
                        let elapsed = Date().timeIntervalSince(self.lastHeartbeat)
                        if elapsed > AppConstants.offlineWarningThreshold {
                            self.setState(.unknown)
                        }
                    }
                }
                return
            }

            let status = json["status"] as? String ?? ""
            let heartbeat = (json["heartbeat"] as? NSNumber)?.intValue ?? 0
            let tc = (json["transition_count"] as? NSNumber)?.intValue ?? 0

            DispatchQueue.main.async {
                guard !status.isEmpty else { return }
                
                // 如果没有 heartbeat 字段，使用当前时间
                let heartbeatValue = heartbeat > 0 ? heartbeat : Int(Date().timeIntervalSince1970)
                self.fileExisted = true
                self.lastHeartbeat = Date(timeIntervalSince1970: TimeInterval(heartbeatValue))
                self.currentTask = json["current_task"] as? String
                if self.currentTask == nil {
                    self.currentTask = json["message"] as? String
                }

                guard !self.isPaused else { return }

                // 短任务处理
                if self.lastTransitionCount > 0 && tc > self.lastTransitionCount + 1 && status == "done" {
                    self.handleShortTask()
                    self.lastTransitionCount = tc
                    return
                }
                self.lastTransitionCount = tc

                let targetState: TrafficLightState
                switch status {
                case "idle":      targetState = .idle
                case "working":   targetState = .working
                case "done":      targetState = .done
                case "completed": targetState = .done
                case "waiting":   targetState = .waiting
                case "attention": targetState = .waiting
                case "blocked":   targetState = .waiting
                default:          return
                }

                if targetState != self.currentDisplayState {
                    NSLog("[TrafficLight] 状态变化: \(self.currentDisplayState) → \(targetState)")
                }
                self.setState(targetState)
            }
        }
    }

    private func handleShortTask() {
        applyState(.working)
        minDisplayTimer?.invalidate()
        minDisplayTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.applyState(.done)
        }
    }

    private func setState(_ newState: TrafficLightState) {
        let old = currentDisplayState
        guard newState != old else { return }

        let elapsed = CACurrentMediaTime() - lastStateChangeTime
        if old == .working && newState == .done && elapsed < 0.3 {
            minDisplayTimer?.invalidate()
            minDisplayTimer = Timer.scheduledTimer(
                withTimeInterval: 0.3 - elapsed, repeats: false
            ) { [weak self] _ in
                self?.applyState(newState)
            }
            return
        }

        applyState(newState)
    }

    private func applyState(_ state: TrafficLightState) {
        currentDisplayState = state
        lastStateChangeTime = CACurrentMediaTime()

        if state == .done {
            startCountdown()
            TaskTimingStore.shared.finishWorking(task: currentTask)
        } else if state == .working {
            TaskTimingStore.shared.startWorking()
            stopCountdown()
        } else {
            TaskTimingStore.shared.cancelWorking()
            stopCountdown()
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onStatusChanged?(state, self.currentTask)
            if state == .done {
                self.onDoneStateEntered?(self.lastTransitionCount, self.currentTask)
            }
        }
    }

    // MARK: - 倒计时

    private func startCountdown() {
        doneStateTimestamp = Date()
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.doneStateTimestamp else { return }
            let dur = TimeInterval(SettingsManager.shared.greenLightDuration)
            self.greenRemainingSeconds = max(0, dur + start.timeIntervalSinceNow)
            if self.greenRemainingSeconds <= 0 && self.currentDisplayState == .done {
                self.applyState(.idle)
            }
        }
        if let timer = countdownTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        doneStateTimestamp = nil
        greenRemainingSeconds = 0
    }
}
