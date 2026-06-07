import Cocoa

/// 菜单顶部标题栏 — 三灯图标 + 状态文字 + 任务信息/倒计时
class MenuHeaderView: NSView {

    static let fixedWidth: CGFloat = AppConstants.menuHeaderWidth
    static let fixedHeight: CGFloat = AppConstants.menuHeaderHeight

    var state: TrafficLightState = .idle
    var task: String?
    var remainingSeconds: TimeInterval = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: Self.fixedWidth, height: Self.fixedHeight))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        // 背景
        NSColor.controlBackgroundColor.setFill()
        bounds.fill()

        // 底部分割线
        NSColor.separatorColor.setFill()
        NSRect(x: 8, y: 1, width: bounds.width - 16, height: 0.5).fill()

        // === 顶部行：图标 + 状态 ===
        let topY = Self.fixedHeight - 16
        drawTrafficLights(at: NSPoint(x: 12, y: topY))
        drawStateLabel(at: NSPoint(x: 56, y: topY - 5))

        // === 底部行：任务或倒计时 ===
        let bottomY: CGFloat = 16
        if state == .done {
            if remainingSeconds > 0 {
                drawCountdown(at: NSPoint(x: 56, y: bottomY))
            } else {
                drawText("⏱ 即将切换为空闲…", at: NSPoint(x: 56, y: bottomY),
                         font: .systemFont(ofSize: 11), color: .systemOrange)
            }
        } else if let task = task, !task.isEmpty,
                  (state == .working || state == .done),
                  SettingsManager.shared.showTaskDescription {
            let truncated = String(task.prefix(35)) + (task.count > 35 ? "…" : "")
            drawText("任务：" + truncated, at: NSPoint(x: 56, y: bottomY),
                     font: .systemFont(ofSize: 11), color: .secondaryLabelColor)
        } else if state == .unknown {
            drawText("超过 \(Int(AppConstants.offlineWarningThreshold)) 秒未收到状态更新",
                     at: NSPoint(x: 56, y: bottomY),
                     font: .systemFont(ofSize: 11), color: .secondaryLabelColor)
        }
    }

    // MARK: - 三灯图标

    private func drawTrafficLights(at origin: NSPoint) {
        let radius: CGFloat = 4.5
        let step: CGFloat = 13
        let y = origin.y - radius

        let lightStates: [TrafficLightState] = [.waiting, .done, .working]
        for (i, ls) in lightStates.enumerated() {
            let active = ls == state
            let cx = origin.x + radius + CGFloat(i) * step

            let color: NSColor
            if state == .paused || state == .unknown {
                color = NSColor(white: 0.65, alpha: 1.0)
            } else if active {
                switch ls {
                case .waiting: color = NSColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
                case .done:    color = NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
                case .working: color = NSColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)
                default:       color = .gray
                }
            } else {
                color = NSColor(white: 0.85, alpha: 1.0)
            }

            let rect = NSRect(x: cx - radius, y: y, width: radius * 2, height: radius * 2)
            color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            NSColor.black.withAlphaComponent(0.1).setStroke()
            NSBezierPath(ovalIn: rect).lineWidth = 0.5
            NSBezierPath(ovalIn: rect).stroke()
        }
    }

    // MARK: - 状态文字

    private func drawStateLabel(at origin: NSPoint) {
        let text = state.label
        let attr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        (text as NSString).draw(at: origin, withAttributes: attr)
    }

    // MARK: - 倒计时

    private func drawCountdown(at origin: NSPoint) {
        let m = Int(remainingSeconds) / 60
        let s = Int(remainingSeconds) % 60
        let text = m > 0
            ? String(format: "⏱ %d:%02d 后自动切换为空闲", m, s)
            : String(format: "⏱ %d 秒后自动切换为空闲", s)
        let color: NSColor = remainingSeconds < 10 ? .systemOrange : .tertiaryLabelColor
        drawText(text, at: origin,
                 font: .monospacedDigitSystemFont(ofSize: 11, weight: .regular),
                 color: color)
    }

    // MARK: - 辅助

    private func drawText(_ text: String, at origin: NSPoint, font: NSFont, color: NSColor) {
        (text as NSString).draw(at: origin, withAttributes: [
            .font: font,
            .foregroundColor: color
        ])
    }
}
