import Cocoa

/// AI Traffic Light — macOS 菜单栏状态指示器
///
/// 配置文件读取路径：~/.ai-traffic-light/status.json
///
/// 架构：
///   - main.swift              → 创建应用实例
///   - AppDelegate.swift       → 应用生命周期 + 菜单
///   - TrafficLightView        → 红绿灯视图（NSView draw）
///   - StatusMonitor           → 轮询 status.json（1秒间隔）
///   - SettingsManager         → UserDefaults 设置
///   - SettingsView            → SwiftUI 设置面板
///   - NotificationManager     → 系统通知
///   - AutoLaunchManager       → 登录自启动
///   - TaskTimingStore         → 任务耗时统计

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Accessory 模式：显示菜单栏，隐藏 Dock 图标
app.setActivationPolicy(.accessory)

app.run()
