import ServiceManagement
import Cocoa

// MARK: - 登录自启动管理器

class AutoLaunchManager {
    static let shared = AutoLaunchManager()
    private init() {}

    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // macOS 12 及以下使用旧的 SMLoginItemSetEnabled
            return false
        }
    }

    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    NSLog("[TrafficLight] SMAppService: 已注册登录自启动")
                } else {
                    try SMAppService.mainApp.unregister()
                    NSLog("[TrafficLight] SMAppService: 已注销登录自启动")
                }
            } catch {
                NSLog("[TrafficLight] SMAppService 操作失败: \(error.localizedDescription)")
            }
        } else {
            // Fallback on earlier versions
            let bundleID = Bundle.main.bundleIdentifier ?? "com.ai.traffic-light"
            SMLoginItemSetEnabled(bundleID as CFString, enabled)
        }
    }
}
