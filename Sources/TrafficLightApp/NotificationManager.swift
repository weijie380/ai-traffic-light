import UserNotifications
import Cocoa

// MARK: - 系统通知管理器

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() {}

    private var lastNotifiedTransitionCount: Int = -1
    private var pendingWorkItem: DispatchWorkItem?

    static let categoryIdentifier = "ai.trafficlight.done"

    // MARK: - 设置

    func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        requestPermission()
        registerCategories()
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                NSLog("[TrafficLight] 通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }

    private func registerCategories() {
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - 通知发送

    func notifyIfDone(state: TrafficLightState, transitionCount tc: Int, task: String?) {
        guard state == .done else { return }
        guard SettingsManager.shared.notificationEnabled else { return }
        guard tc > lastNotifiedTransitionCount else { return }
        guard !StatusMonitor.shared.isPaused else { return }

        lastNotifiedTransitionCount = tc

        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard StatusMonitor.shared.currentDisplayState == .done else { return }
            self.send(task: task)
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func send(task: String?) {
        let content = UNMutableNotificationContent()
        content.title = "AI Traffic Light"
        content.subtitle = "任务已完成"

        var bodyParts: [String] = []
        if let t = task, SettingsManager.shared.showTaskDescription, !t.isEmpty {
            let truncated = String(t.prefix(50)) + (t.count > 50 ? "…" : "")
            bodyParts.append(truncated)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        bodyParts.append("完成时间：\(formatter.string(from: Date()))")
        content.body = bodyParts.joined(separator: "\n")

        content.categoryIdentifier = Self.categoryIdentifier
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "ai.done.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("[TrafficLight] 通知发送失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
        completionHandler()
    }
}
