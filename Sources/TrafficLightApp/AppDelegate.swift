import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    // MARK: - 组件

    private var statusItem: NSStatusItem!
    private var trafficLightView: TrafficLightView!
    private var statusMonitor: StatusMonitor!
    private var menuHeaderView: MenuHeaderView?
    private var menuRefreshTimer: Timer?
    private var menu: NSMenu!

    // MARK: - 应用启动

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建菜单栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = ""
            button.image = nil
            trafficLightView = TrafficLightView(frame: .zero)
            button.addSubview(trafficLightView)
            button.frame = NSRect(x: 0, y: 0,
                                  width: AppConstants.menuBarWidth,
                                  height: AppConstants.menuBarHeight)
            button.toolTip = "AI Traffic Light — 空闲"
        }

        // 菜单
        menu = NSMenu()
        menu.delegate = self
        menu.minimumWidth = AppConstants.menuHeaderWidth
        statusItem.menu = menu

        // 加载设置
        SettingsManager.shared.load()
        NotificationManager.shared.setup()

        // 状态监控
        statusMonitor = StatusMonitor.shared
        statusMonitor.onStatusChanged = { [weak self] state, task in
            DispatchQueue.main.async {
                self?.applyStateUpdate(state, task: task)
            }
        }
        statusMonitor.onDoneStateEntered = { tc, task in
            DispatchQueue.main.async {
                NotificationManager.shared.notifyIfDone(
                    state: .done,
                    transitionCount: tc,
                    task: task
                )
            }
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(greenLightDurationDidChange),
            name: .greenLightDurationChanged, object: nil)

        statusMonitor.start()

        // 同步登录自启动
        if AutoLaunchManager.shared.isEnabled != SettingsManager.shared.autoLaunchEnabled {
            AutoLaunchManager.shared.setEnabled(SettingsManager.shared.autoLaunchEnabled)
        }
    }

    // MARK: - 状态更新

    private func applyStateUpdate(_ state: TrafficLightState, task: String?) {
        trafficLightView.transitionToState(state)
        statusItem.button?.toolTip = tooltip(for: state, task: task)
        if let headerView = menuHeaderView {
            headerView.state = state
            headerView.task = task
            headerView.remainingSeconds = statusMonitor.greenRemainingSeconds
            headerView.needsDisplay = true
        }
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        menuHeaderView = nil
        menuRefreshTimer?.invalidate()

        // 标题栏
        let headerItem = NSMenuItem()
        let headerView = MenuHeaderView()
        headerView.state = statusMonitor.currentDisplayState
        headerView.task = statusMonitor.currentTask
        headerView.remainingSeconds = statusMonitor.greenRemainingSeconds
        headerItem.view = headerView
        menu.addItem(headerItem)
        menuHeaderView = headerView

        menu.addItem(NSMenuItem.separator())

        // 重置为空闲
        if !statusMonitor.isPaused {
            let resetItem = NSMenuItem(
                title: "重置为空闲",
                action: #selector(resetIdle),
                keyEquivalent: ""
            )
            resetItem.target = self
            resetItem.isEnabled = statusMonitor.currentDisplayState != .idle
            menu.addItem(resetItem)
        }

        // 暂停/恢复
        let pauseTitle = statusMonitor.isPaused ? "恢复指示器" : "暂停指示器"
        let pauseItem = NSMenuItem(title: pauseTitle, action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)

        menu.addItem(NSMenuItem.separator())

        // 设置
        let settingsItem = NSMenuItem(
            title: "设置…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        menu.addItem(settingsItem)

        // 关于
        menu.addItem(NSMenuItem(
            title: "关于 AI Traffic Light",
            action: #selector(showAbout),
            keyEquivalent: ""
        ).withTarget(self))

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)

        // done 状态倒计时刷新
        if statusMonitor.currentDisplayState == .done {
            menuRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self, let hv = self.menuHeaderView else { return }
                hv.remainingSeconds = self.statusMonitor.greenRemainingSeconds
                hv.needsDisplay = true
            }
            if let t = menuRefreshTimer {
                RunLoop.main.add(t, forMode: .common)
            }
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        menuRefreshTimer?.invalidate()
        menuRefreshTimer = nil
    }

    // MARK: - Actions

    @objc private func resetIdle() {
        statusMonitor.resetToIdle()
    }

    @objc private func togglePause() {
        statusMonitor.togglePause()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "AI Traffic Light"
        alert.informativeText = "版本 v0.3.0\nmacOS 菜单栏状态指示器\n\n兼容 Reasonix / Claude Code / OpenCode / 任何 AI 工具"
        alert.alertStyle = .informational
        alert.icon = NSImage(named: NSImage.applicationIconName)
        alert.runModal()
    }

    @objc private func quit() {
        statusMonitor.stop()
        NSApp.terminate(nil)
    }

    @objc private func greenLightDurationDidChange() {
        statusMonitor.recalculateCountdown()
    }

    // MARK: - 工具提示

    private func tooltip(for state: TrafficLightState, task: String?) -> String {
        switch state {
        case .idle:
            return "AI Traffic Light — 空闲"
        case .working:
            return "AI 工作中…" + (task.map { "\n任务：\($0)" } ?? "")
        case .done:
            let r = Int(statusMonitor.greenRemainingSeconds)
            return r > 60
                ? "AI 已完成（\(r/60)分钟后切换）"
                : "AI 已完成（\(r)秒后切换）"
        case .waiting:
            return "AI 等待授权…" + (task.map { "\n\($0)" } ?? "")
        case .paused:
            return "已暂停"
        case .unknown:
            return "状态未知"
        }
    }
}

// MARK: - 辅助

private extension NSMenuItem {
    @discardableResult
    func withTarget(_ target: AnyObject) -> NSMenuItem {
        self.target = target
        return self
    }
}
