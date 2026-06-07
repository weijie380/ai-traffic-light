import Foundation

// MARK: - 任务计时记录

struct TaskTimingRecord {
    let index: Int
    let duration: Double
    let timestamp: Date
    let task: String?
}

/// 记录每次 working → done 的耗时，最多保留 N 条。
class TaskTimingStore {
    static let shared = TaskTimingStore()
    private init() {}

    private var records: [TaskTimingRecord] = []
    private var workingStartTime: Date?
    private var nextIndex: Int = 1

    func startWorking() {
        workingStartTime = Date()
    }

    func finishWorking(task: String?) {
        guard let start = workingStartTime else { return }
        workingStartTime = nil
        let duration = Date().timeIntervalSince(start)
        guard duration >= AppConstants.timingMinDuration else { return }

        let record = TaskTimingRecord(
            index: nextIndex,
            duration: duration,
            timestamp: Date(),
            task: task
        )
        if records.count >= AppConstants.timingRingCapacity {
            records.removeFirst()
        }
        records.append(record)
        nextIndex += 1
        NotificationCenter.default.post(name: .taskTimingUpdated, object: nil)
    }

    func cancelWorking() {
        workingStartTime = nil
    }

    func lastRecord() -> TaskTimingRecord? {
        records.last
    }

    func allRecords() -> [TaskTimingRecord] {
        records.reversed()
    }

    static func formatDuration(_ duration: TimeInterval) -> String {
        if duration >= 60 {
            let m = Int(duration) / 60
            return String(format: "%d 分 %.1f 秒", m, duration - Double(m * 60))
        }
        return String(format: "%.1f 秒", duration)
    }
}
