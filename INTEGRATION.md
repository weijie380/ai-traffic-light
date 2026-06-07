# 🚦 AI Traffic Light 集成指南

## 快速配置

### 1. OpenCode（已配置 ✅）

你的 OpenCode alias 已经配置好了：
```bash
alias opencode='/Library/code/pycharmcode/ai-traffic-light/scripts/opencode-wrapper.sh'
```

**使用方法：**
```bash
# 重新加载 shell（如果刚配置）
source ~/.zshrc

# 现在运行 opencode 会自动显示红绿灯
opencode
```

**效果：**
- 🟢 启动时：绿灯闪烁（运行中）
- 🟡 正常退出：黄灯常亮（完成）
- 🔴 异常退出：红灯闪烁（等待处理）

### 2. Reasonix

**方式一：在代码中直接调用（推荐）**

在 Reasonix 的代码中添加以下调用：

```python
import subprocess
import os

TRAFFIC_LIGHT = "/Library/code/pycharmcode/ai-traffic-light/scripts/reasonix-integration.sh"

def start_task(task_name):
    """任务开始时调用"""
    subprocess.run([TRAFFIC_LIGHT, "start", "Reasonix", task_name])

def end_task(task_name):
    """任务完成时调用"""
    subprocess.run([TRAFFIC_LIGHT, "end", "Reasonix", task_name])

def error_task(error_msg):
    """遇到错误时调用"""
    subprocess.run([TRAFFIC_LIGHT, "error", "Reasonix", error_msg])

def permission_task(permission_msg):
    """需要用户授权时调用"""
    subprocess.run([TRAFFIC_LIGHT, "permission", "Reasonix", permission_msg])
```

**使用示例：**
```python
# 在你的 Reasonix 代码中
start_task("分析代码库")
# ... 执行你的任务 ...
end_task("代码重构完成")
```

**方式二：使用 Python CLI**

```bash
# 开始任务
python3 -m signal_light play working "Reasonix" "分析代码"

# 任务完成
python3 -m signal_light play completed "Reasonix" "完成"

# 需要授权
python3 -m signal_light play waiting "Reasonix" "等待授权"
```

**方式三：直接写 JSON 文件**

```python
import json
import time

status_file = "/Library/code/pycharmcode/ai-traffic-light/.ai-traffic-light/status.json"

data = {
    "status": "working",
    "signal": "working",
    "tool": "Reasonix",
    "message": "正在分析代码...",
    "heartbeat": int(time.time()),
    "transition_count": 1
}

with open(status_file, "w") as f:
    json.dump(data, f, indent=2)
```

## 测试集成

```bash
cd /Library/code/pycharmcode/ai-traffic-light

# 测试 OpenCode（如果已配置）
opencode --version

# 测试 Reasonix 集成
./scripts/reasonix-integration.sh start "Reasonix" "测试任务"
# 观察菜单栏红绿灯变化
./scripts/reasonix-integration.sh end "Reasonix" "测试完成"
```

## 故障排除

### 1. 红绿灯没有变化
- 检查状态文件：`cat ~/.ai-traffic-light/status.json`
- 确认 App 正在运行：查看菜单栏是否有红绿灯图标

### 2. macOS 显示"已损坏"
```bash
xattr -cr /Applications/AI\ Traffic\ Light.app
```

### 3. 权限错误
确保脚本有执行权限：
```bash
chmod +x /Library/code/pycharmcode/ai-traffic-light/scripts/*.sh
```

## 高级配置

### 自动启动 App
1. 打开 AI Traffic Light App
2. 按 ⌘, 打开设置
3. 勾选"登录时自动启动"

### Web UI（可选）
```bash
# 启动 Python 后端服务器
python3 -m signal_light serve

# 访问 Web 界面
open http://localhost:19876
```

### 状态文件路径
- 优先：`/Library/code/pycharmcode/ai-traffic-light/.ai-traffic-light/status.json`
- 备选：`~/.ai-traffic-light/status.json`
