import SwiftUI
import Combine

// MARK: - 设置视图模型

/// ObservableObject 桥接 SettingsManager，提供 SwiftUI 数据绑定。
class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()
    private let manager = SettingsManager.shared

    @Published var greenLightDuration: Int {
        didSet {
            manager.greenLightDuration = greenLightDuration
            NotificationCenter.default.post(name: .greenLightDurationChanged, object: nil)
        }
    }

    @Published var colorBlindMode: ColorBlindMode {
        didSet {
            manager.colorBlindMode = colorBlindMode
            NotificationCenter.default.post(name: .colorBlindModeChanged, object: nil)
        }
    }

    @Published var autoLaunchEnabled: Bool {
        didSet {
            manager.autoLaunchEnabled = autoLaunchEnabled
            AutoLaunchManager.shared.setEnabled(autoLaunchEnabled)
        }
    }

    @Published var notificationEnabled: Bool {
        didSet { manager.notificationEnabled = notificationEnabled }
    }

    @Published var showTaskDescription: Bool {
        didSet { manager.showTaskDescription = showTaskDescription }
    }

    private init() {
        greenLightDuration  = manager.greenLightDuration
        colorBlindMode      = manager.colorBlindMode
        autoLaunchEnabled   = manager.autoLaunchEnabled
        notificationEnabled = manager.notificationEnabled
        showTaskDescription = manager.showTaskDescription
    }

    func resetToDefaults() {
        manager.resetToDefaults()
        greenLightDuration  = manager.greenLightDuration
        colorBlindMode      = manager.colorBlindMode
        autoLaunchEnabled   = manager.autoLaunchEnabled
        notificationEnabled = manager.notificationEnabled
        showTaskDescription = manager.showTaskDescription
        AutoLaunchManager.shared.setEnabled(autoLaunchEnabled)
    }

    var formattedDuration: String {
        let s = greenLightDuration
        if s < 60 { return "\(s) 秒" }
        let m = s / 60
        let r = s % 60
        return r == 0 ? "\(s) 秒（\(m) 分钟）" : "\(s) 秒（\(m) 分 \(r) 秒）"
    }
}
