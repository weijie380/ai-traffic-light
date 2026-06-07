import SwiftUI
import Cocoa

// MARK: - 设置面板

struct SettingsView: View {
    @ObservedObject var vm = SettingsViewModel.shared
    @State private var showResetAlert = false

    var body: some View {
        TabView {
            GeneralTab(vm: vm, showResetAlert: $showResetAlert)
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

            AboutTab()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 420)
        .padding(.top, 8)
    }
}

// MARK: - 通用设置页

struct GeneralTab: View {
    @ObservedObject var vm: SettingsViewModel
    @Binding var showResetAlert: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // === 绿灯持续时间 ===
            GroupBox(label: Text("绿灯持续时间").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("30 秒").font(.caption).foregroundColor(.secondary)
                            .frame(width: 45, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(vm.greenLightDuration) },
                            set: { vm.greenLightDuration = Int($0) }
                        ), in: 30...1800, step: 10)
                        Text("30 分钟").font(.caption).foregroundColor(.secondary)
                            .frame(width: 55, alignment: .trailing)
                    }
                    Text(vm.formattedDuration)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // === 色盲模式 ===
            GroupBox(label: Text("色盲模式").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("模式", selection: $vm.colorBlindMode) {
                        Text("关闭（仅颜色）").tag(ColorBlindMode.off)
                        Text("形状辅助（颜色 + 形状）").tag(ColorBlindMode.shapeAssist)
                        Text("仅形状（灰阶 + 形状）").tag(ColorBlindMode.shapeOnly)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()

                    HStack {
                        TrafficLightStaticPreview(mode: vm.colorBlindMode)
                            .frame(width: 160, height: 32)
                        Text(modeDescription(vm.colorBlindMode))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .windowBackgroundColor))
                    )
                }
                .padding(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // === 通用开关 ===
            GroupBox(label: Text("通用").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("登录时自动启动", isOn: $vm.autoLaunchEnabled)
                    Toggle("任务完成时发送通知", isOn: $vm.notificationEnabled)
                    Toggle("菜单中显示任务简述", isOn: $vm.showTaskDescription)
                }
                .padding(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // === 底部 ===
            HStack {
                Button("恢复默认") { showResetAlert = true }
                    .buttonStyle(.link)
                Spacer()
                Text("AI Traffic Light v0.3.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
        }
        .alert("恢复默认设置", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) { }
            Button("恢复默认", role: .destructive) { vm.resetToDefaults() }
        } message: {
            Text("所有设置将恢复到默认值。")
        }
    }

    func modeDescription(_ mode: ColorBlindMode) -> String {
        switch mode {
        case .off:         return "纯颜色区分"
        case .shapeAssist: return "颜色 + 形状双重区分"
        case .shapeOnly:   return "灰阶 + 形状区分"
        }
    }
}

// MARK: - 关于页

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSImage(named: NSImage.applicationIconName)
                  ?? NSImage())
                .resizable()
                .frame(width: 80, height: 80)

            Text("AI Traffic Light")
                .font(.title2)
                .fontWeight(.semibold)

            Text("版本 v0.3.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("macOS 菜单栏状态指示器\n实时显示 AI 工具的工作状态")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 静态预览

class TrafficLightStaticPreviewView: NSView {
    var mode: ColorBlindMode = .shapeAssist

    override init(frame frameRect: NSRect) { super.init(frame: frameRect) }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let radius: CGFloat = 6
        let step = radius * 2 + 5
        let y = bounds.height / 2
        let lights: [(NSColor, TrafficLightState)] = [
            (NSColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0), .waiting),
            (NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0), .done),
            (NSColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0), .working),
        ]
        for (i, (color, state)) in lights.enumerated() {
            let cx = 8 + radius + CGFloat(i) * step
            let r = NSRect(x: cx - radius, y: y - radius,
                           width: radius * 2, height: radius * 2)
            (mode == .shapeOnly ? NSColor(white: 0.3, alpha: 1.0) : color).setFill()
            if mode != .off {
                switch state {
                case .waiting:
                    NSBezierPath(ovalIn: r).fill()
                case .working:
                    let p = NSBezierPath()
                    let m = r.midX, my = r.midY
                    p.move(to: NSPoint(x: m, y: r.maxY))
                    p.line(to: NSPoint(x: r.maxX, y: my))
                    p.line(to: NSPoint(x: m, y: r.minY))
                    p.line(to: NSPoint(x: r.minX, y: my))
                    p.close(); p.fill()
                case .done:
                    NSBezierPath(roundedRect: r, xRadius: 2, yRadius: 2).fill()
                default:
                    NSBezierPath(ovalIn: r).fill()
                }
            } else {
                NSBezierPath(ovalIn: r).fill()
            }
        }
    }
}

struct TrafficLightStaticPreview: NSViewRepresentable {
    let mode: ColorBlindMode

    func makeNSView(context: Context) -> TrafficLightStaticPreviewView {
        let v = TrafficLightStaticPreviewView(
            frame: NSRect(x: 0, y: 0, width: 160, height: 32)
        )
        v.mode = mode
        return v
    }

    func updateNSView(_ v: TrafficLightStaticPreviewView, context: Context) {
        v.mode = mode
        v.needsDisplay = true
    }
}
