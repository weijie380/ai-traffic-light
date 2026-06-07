[![Download](https://img.shields.io/badge/Download-v0.3.0-blue)](https://github.com/weijie380/ai-traffic-light/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/weijie380/ai-traffic-light/blob/main/LICENSE)

# 🚦 AI Traffic Light

> 实时显示 AI 工具工作状态的 macOS 菜单栏红绿灯。

**红 🔴** — 等待用户授权  
**黄 🟡** — 任务已完成  
**绿 🟢** — 任务运行中  
**灰 ⚫** — 空闲 / 无活跃任务

<!-- ![screenshot](docs/screenshot.png) -->

---

## ✨ 特性

- **菜单栏原生 App** — 纯 Swift 编译，启动即用，无任何依赖
- **自动检测** — 轮询 `~/.ai-traffic-light/status.json`，实时更新
- **设置面板** — ⌘, 打开：绿灯时长、色盲模式、通知、登录自启
- **系统通知** — 任务完成时横幅提醒
- **色盲友好** — 颜色 + 形状双重编码
- **绿灯倒计时** — 完成任务后自动超时回空闲
- **暂停/恢复** — 临时冻结状态指示
- **通用兼容** — 任何 AI 工具（Reasonix、Claude Code、OpenCode 等）
- **可选 Web UI** — `traffic-light.html` 配合 Python 服务器可显示悬浮窗

---

## 🚀 快速开始

### 方式一：下载编译好的 App（推荐）

从 [GitHub Releases](https://github.com/weijie380/ai-traffic-light/releases) 下载最新版：
1. 下载 `AI Traffic Light.app.zip` → 解压 → 拖入 Applications
2. 首次运行：**右键 → 打开**（或从 Launchpad 打开）
3. 菜单栏出现红绿灯 🚦

**⚠️ macOS 安全提示：** 如果看到"已损坏，无法打开"，这是因为 macOS 的 Gatekeeper 安全机制。解决方法：
```bash
# 方法1：在终端运行（推荐）
xattr -cr /Applications/AI\ Traffic\ Light.app

# 方法2：系统偏好设置 → 安全性与隐私 → 通用 → 点击"仍要打开"
```
然后重新从 Applications 启动 App。

### 方式二：从源码构建

需要 macOS 13+ 和 Command Line Tools（约 1.5GB）：

```bash
# 安装 Command Line Tools（如果没有）
xcode-select --install

# 构建并安装
cd ai-traffic-light
make install    # 编译 + 打包 .app + 安装到 /Applications
```

---

## 🔧 集成你的 AI 工具

### OpenCode

安装 wrapper 脚本后，OpenCode 启动/完成时自动更新状态：

```bash
# 设置 alias
echo 'alias opencode="/path/to/ai-traffic-light/scripts/opencode-wrapper.sh"' >> ~/.zshrc
```

### Claude Code

安装 hooks：

```bash
# 一键安装 hooks
cd ai-traffic-light
bash scripts/install.sh
```

### Reasonix / 自定义

直接写文件 `~/.ai-traffic-light/status.json`：

```json
{
  "status": "working",
  "signal": "working",
  "tool": "Reasonix",
  "message": "正在分析代码...",
  "heartbeat": 1717700000,
  "transition_count": 3
}
```

或用命令行：

```bash
python3 -m signal_light play working Reasonix "分析中..."
python3 -m signal_light play waiting Reasonix "等待确认"
python3 -m signal_light play completed Reasonix "完成"
```

### HTTP API（配合 Python 后端）

```bash
# 启动服务器
python3 -m signal_light serve

# 然后通过 HTTP 更新
curl -X POST http://127.0.0.1:19876/update \
  -H "Content-Type: application/json" \
  -d '{"signal":"working","tool":"MyTool","message":"处理中..."}'
```

---

## ⚙️ 设置

| 功能 | 说明 | 默认 |
|------|------|------|
| 绿灯时长 | 30秒 ~ 30分钟 | 5分钟 |
| 色盲模式 | 纯颜色 / 颜色+形状 / 仅灰阶形状 | 颜色+形状 |
| 登录自启 | 开机自动启动 | ✅ |
| 系统通知 | 任务完成时横幅提醒 | ✅ |
| 菜单任务简述 | 菜单中显示当前任务 | ✅ |

---

## 📁 项目结构

```
ai-traffic-light/
├── Sources/TrafficLightApp/
│   ├── main.swift               # 入口
│   ├── AppDelegate.swift         # 菜单栏 + 菜单 + 生命周期
│   ├── TrafficLightView.swift    # 三圆点绘制（NSView）
│   ├── TrafficLightState.swift   # 状态枚举 + 色盲模式
│   ├── StatusMonitor.swift       # 轮询 status.json
│   ├── SettingsManager.swift     # 设置管理（UserDefaults）
│   ├── SettingsViewModel.swift   # 设置数据绑定
│   ├── SettingsView.swift        # SwiftUI 设置面板
│   ├── SettingsWindowController.swift # 设置窗口
│   ├── MenuHeaderView.swift      # 菜单标题栏
│   ├── NotificationManager.swift # 系统通知
│   ├── AutoLaunchManager.swift   # 登录自启动
│   ├── TaskTimingStore.swift     # 任务耗时统计
│   └── Constants.swift           # 常量和通知名
├── traffic-light.html            # Web UI（可选）
├── signal_light/                 # Python CLI
├── scripts/                      # 集成脚本
├── Makefile                      # 一键构建
└── Package.swift                 # SPM 项目定义（备用）
```

---

## 🛠 开发

```bash
make build    # 编译
make run      # 运行
make bundle   # 打包 .app
make install  # 安装到 /Applications
make dist     # 打包为 zip（用于分发）
make clean    # 清理
```

---

## 📝 License

MIT
