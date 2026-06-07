import Foundation

// MARK: - 通知名称

extension Notification.Name {
    static let colorBlindModeChanged   = Notification.Name("ai.tl.colorBlindModeChanged")
    static let greenLightDurationChanged = Notification.Name("ai.tl.greenLightDurationChanged")
    static let taskTimingUpdated       = Notification.Name("ai.tl.taskTimingUpdated")
}

// MARK: - 常量

enum AppConstants {
    /// 离线判定阈值：超过此秒数未收到心跳视为未知状态
    static let offlineWarningThreshold: TimeInterval = 15
    /// 离线严重阈值
    static let offlineSevereThreshold: TimeInterval = 30

    /// 计时环容量（最多保留几次任务记录）
    static let timingRingCapacity = 5
    /// 最短记录时长（小于此值不记入计时）
    static let timingMinDuration: TimeInterval = 0.3

    /// 菜单栏固定尺寸
    static let menuBarWidth: CGFloat = 58  // 增加宽度
    static let menuBarHeight: CGFloat = 26 // 增加高度

    /// 菜单标题栏尺寸
    static let menuHeaderWidth: CGFloat = 240
    static let menuHeaderHeight: CGFloat = 56

    /// 状态文件路径（相对于用户 Home）
    static let statusFileRelativePath = ".ai-traffic-light/status.json"
    
    /// 项目目录下的状态文件路径（作为备选）
    static let projectStatusFileRelativePath = "ai-traffic-light/.ai-traffic-light/status.json"
}
