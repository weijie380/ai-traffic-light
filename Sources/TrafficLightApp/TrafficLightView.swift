import Cocoa

// MARK: - 菜单栏红绿灯视图

/// 在菜单栏绘制三个彩色圆点（红-黄-绿），遵循标准交通灯顺序。
class TrafficLightView: NSView {

    // MARK: - 绘制参数

    private let dotRadius: CGFloat = 5.0
    private let spacing: CGFloat = 4.0
    private let padding: CGFloat = 2.0

    private var totalWidth: CGFloat {
        padding * 2 + dotRadius * 6 + spacing * 2
    }

    private(set) var currentState: TrafficLightState = .idle
    private var blinkTimer: Timer?
    private var isBlinkOn = true

    // MARK: - 生命周期

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(colorBlindModeDidChange),
            name: .colorBlindModeChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        blinkTimer?.invalidate()
    }

    @objc private func colorBlindModeDidChange() {
        needsDisplay = true
    }

    // MARK: - 状态切换

    func transitionToState(_ state: TrafficLightState) {
        currentState = state
        blinkTimer?.invalidate()
        blinkTimer = nil

        if state == .working || state == .waiting {
            isBlinkOn = true
            blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.isBlinkOn.toggle()
                self.needsDisplay = true
            }
            RunLoop.main.add(blinkTimer!, forMode: .common)
        }

        needsDisplay = true
    }

    // MARK: - 绘制

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let y = bounds.height / 2
        let step = dotRadius * 2 + spacing

        // 三灯顺序：红(等待) - 黄(完成) - 绿(工作)
        let lights: [(center: CGPoint, state: TrafficLightState)] = [
            (CGPoint(x: padding + dotRadius, y: y),           .waiting),
            (CGPoint(x: padding + dotRadius + step, y: y),    .done),
            (CGPoint(x: padding + dotRadius + step * 2, y: y),.working),
        ]

        let mode = SettingsManager.shared.colorBlindMode

        for (center, lightState) in lights {
            let isActive = lightState == currentState
            let isLit: Bool

            if currentState == .paused || currentState == .unknown {
                isLit = false
            } else if currentState == .working || currentState == .waiting {
                isLit = isActive ? isBlinkOn : false
            } else {
                isLit = isActive
            }

            let color = colorForLight(lightState)
            let alpha: CGFloat = isLit ? 1.0 : 0.25
            let rect = NSRect(
                x: center.x - dotRadius, y: center.y - dotRadius,
                width: dotRadius * 2, height: dotRadius * 2
            )

            if mode == .shapeOnly {
                NSColor(white: isLit ? 0.3 : 0.7, alpha: alpha).setFill()
                drawShape(for: lightState, in: rect)
            } else {
                color.withAlphaComponent(alpha).setFill()
                if mode == .shapeAssist {
                    drawShape(for: lightState, in: rect)
                } else {
                    NSBezierPath(ovalIn: rect).fill()
                }
            }

            // 边框
            if isLit {
                NSColor.black.withAlphaComponent(0.15).setStroke()
            } else {
                NSColor.black.withAlphaComponent(0.06).setStroke()
            }
            let border = mode == .off
                ? NSBezierPath(ovalIn: rect)
                : shapePath(for: lightState, in: rect)
            border.lineWidth = 0.5
            border.stroke()
        }
    }

    // MARK: - 颜色

    private func colorForLight(_ state: TrafficLightState) -> NSColor {
        switch state {
        case .waiting: return NSColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0) // 红
        case .done:    return NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)   // 亮黄
        case .working: return NSColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)   // 亮绿
        default:       return .gray
        }
    }

    // MARK: - 色盲模式形状

    private func drawShape(for state: TrafficLightState, in rect: NSRect) {
        shapePath(for: state, in: rect).fill()
    }

    private func shapePath(for state: TrafficLightState, in rect: NSRect) -> NSBezierPath {
        switch state {
        case .waiting:
            return NSBezierPath(ovalIn: rect)                         // 圆形
        case .done:
            return NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2) // 圆角矩形
        case .working:
            return diamondPath(in: rect)                              // 菱形
        default:
            return NSBezierPath(ovalIn: rect)
        }
    }

    private func diamondPath(in rect: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        let midX = rect.midX
        let midY = rect.midY
        path.move(to: NSPoint(x: midX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: midY))
        path.line(to: NSPoint(x: midX, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX, y: midY))
        path.close()
        return path
    }
}
