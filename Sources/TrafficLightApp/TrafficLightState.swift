import Foundation

// MARK: - 交通灯状态枚举

enum TrafficLightState: Equatable {
    /// 空闲 — 无活跃任务，全灭
    case idle
    /// 工作中 — AI 正在处理，绿灯
    case working
    /// 已完成 — 任务完成，黄灯
    case done
    /// 等待用户授权/输入 — 红灯
    case waiting
    /// 用户暂停了指示器
    case paused
    /// 超过离线阈值未收到心跳
    case unknown

    /// 状态对应的中文标签
    var label: String {
        switch self {
        case .idle:    return "空闲"
        case .working: return "运行中"
        case .done:    return "已完成"
        case .waiting: return "等待授权"
        case .paused:  return "已暂停"
        case .unknown: return "状态未知"
        }
    }

    /// 状态对应的 emoji
    var emoji: String {
        switch self {
        case .idle:    return "⚫"
        case .working: return "🟢"
        case .done:    return "🟡"
        case .waiting: return "🔴"
        case .paused:  return "⏸"
        case .unknown: return "⚪"
        }
    }
}

// MARK: - 色盲模式

enum ColorBlindMode: String, CaseIterable {
    case off         = "off"
    case shapeAssist = "shapeAssist"
    case shapeOnly   = "shapeOnly"

    var label: String {
        switch self {
        case .off:         return "纯颜色"
        case .shapeAssist: return "颜色 + 形状辅助"
        case .shapeOnly:   return "仅形状（灰阶）"
        }
    }
}
