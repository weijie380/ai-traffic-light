import Cocoa
import Foundation

// MARK: - 设置管理

/// 使用 UserDefaults 持久化用户偏好设置。
class SettingsManager {

    static let shared = SettingsManager()
    private init() {}

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let greenLightDuration  = "greenLightDuration"
        static let colorBlindMode      = "colorBlindMode"
        static let autoLaunchEnabled   = "autoLaunchEnabled"
        static let showTaskDescription = "showTaskDescription"
        static let notificationEnabled = "notificationEnabled"
        static let isPaused            = "isPaused"

        struct Defaults {
            static let greenLightDuration: Int  = 300       // 5分钟
            static let colorBlindMode: String   = "shapeAssist"
            static let autoLaunchEnabled: Bool  = true
            static let showTaskDescription: Bool = true
            static let notificationEnabled: Bool = true
            static let isPaused: Bool           = false
        }
    }

    // MARK: - 属性

    var greenLightDuration: Int {
        get {
            let raw = defaults.integer(forKey: Keys.greenLightDuration)
            guard raw >= 30, raw <= 1800 else { return Keys.Defaults.greenLightDuration }
            return raw
        }
        set { defaults.set(min(max(newValue, 30), 1800), forKey: Keys.greenLightDuration) }
    }

    var colorBlindMode: ColorBlindMode {
        get {
            let raw = defaults.string(forKey: Keys.colorBlindMode) ?? Keys.Defaults.colorBlindMode
            return ColorBlindMode(rawValue: raw) ?? .shapeAssist
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.colorBlindMode) }
    }

    var autoLaunchEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.autoLaunchEnabled) == nil {
                return Keys.Defaults.autoLaunchEnabled
            }
            return defaults.bool(forKey: Keys.autoLaunchEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.autoLaunchEnabled) }
    }

    var showTaskDescription: Bool {
        get {
            if defaults.object(forKey: Keys.showTaskDescription) == nil {
                return Keys.Defaults.showTaskDescription
            }
            return defaults.bool(forKey: Keys.showTaskDescription)
        }
        set { defaults.set(newValue, forKey: Keys.showTaskDescription) }
    }

    var notificationEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.notificationEnabled) == nil {
                return Keys.Defaults.notificationEnabled
            }
            return defaults.bool(forKey: Keys.notificationEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.notificationEnabled) }
    }

    var isPaused: Bool {
        get { return defaults.bool(forKey: Keys.isPaused) }
        set { defaults.set(newValue, forKey: Keys.isPaused) }
    }

    // MARK: - 方法

    func load() {
        _ = greenLightDuration
        _ = colorBlindMode
        _ = autoLaunchEnabled
        _ = showTaskDescription
        _ = notificationEnabled
        syncWithAccessibilitySettings()
    }

    /// 如果系统开启了「区分颜色」，自动启用颜色+形状模式
    private func syncWithAccessibilitySettings() {
        if NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor {
            if colorBlindMode == .off {
                colorBlindMode = .shapeAssist
            }
        }
    }

    func resetToDefaults() {
        defaults.removeObject(forKey: Keys.greenLightDuration)
        defaults.removeObject(forKey: Keys.colorBlindMode)
        defaults.removeObject(forKey: Keys.autoLaunchEnabled)
        defaults.removeObject(forKey: Keys.showTaskDescription)
        defaults.removeObject(forKey: Keys.notificationEnabled)
        defaults.removeObject(forKey: Keys.isPaused)
        syncWithAccessibilitySettings()
    }

    func formattedDuration() -> String {
        let s = greenLightDuration
        if s < 60 { return "\(s) 秒" }
        let m = s / 60
        let r = s % 60
        return r == 0 ? "\(m) 分钟" : "\(m) 分 \(r) 秒"
    }
}
