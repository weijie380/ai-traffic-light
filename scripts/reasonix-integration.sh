#!/bin/bash
# 🚦 AI Traffic Light — Reasonix 集成示例
# 用法：在 Reasonix 的 hooks 或代码中调用此脚本

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 设置状态文件路径（优先用户目录，然后项目目录）
STATUS_FILE=""
for dir in "$HOME/.ai-traffic-light" "$PROJECT_DIR/.ai-traffic-light"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
        STATUS_FILE="$dir/status.json"
        break
    fi
done
if [ -z "$STATUS_FILE" ]; then
    STATUS_FILE="$HOME/.ai-traffic-light/status.json"
    mkdir -p "$(dirname "$STATUS_FILE")"
fi

# 函数：更新状态
update_status() {
    local status="$1"
    local tool="$2"
    local message="$3"
    
    # 确保目录存在
    mkdir -p "$(dirname "$STATUS_FILE")"
    
    # 使用 Python 写入状态文件（更可靠）
    python3 << PYEOF
import json
import time
import os

status_file = "$STATUS_FILE"
try:
    with open(status_file, 'r') as f:
        data = json.load(f)
except:
    data = {}

new_tc = data.get("transition_count", 0) + 1

data = {
    "status": "$status",
    "signal": "$status",
    "tool": "$tool",
    "message": "$message",
    "emoji": "🟢" if "$status" == "working" else ("🟡" if "$status" == "completed" else ("🔴" if "$status" == "waiting" else "⚫")),
    "pattern": "pulse-green" if "$status" == "working" else ("pulse-yellow" if "$status" == "completed" else ("pulse-red" if "$status" == "waiting" else "off")),
    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "heartbeat": int(time.time()),
    "transition_count": new_tc
}

with open(status_file, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
PYEOF
    
    echo "🚦 状态已更新: $status ($tool - $message)"
}

# 示例用法
case "$1" in
    "start")
        update_status "working" "${2:-Reasonix}" "${3:-开始处理任务}"
        ;;
    "end")
        update_status "completed" "${2:-Reasonix}" "${3:-任务完成}"
        ;;
    "error")
        update_status "waiting" "${2:-Reasonix}" "${3:-需要处理错误}"
        ;;
    "permission")
        update_status "waiting" "${2:-Reasonix}" "${3:-等待用户授权}"
        ;;
    *)
        echo "用法: $0 {start|end|error|permission} [tool] [message]"
        echo "示例:"
        echo "  $0 start Reasonix '分析代码库'"
        echo "  $0 end Reasonix '重构完成'"
        echo "  $0 error Reasonix '编译错误'"
        echo "  $0 permission Reasonix '需要文件访问权限'"
        ;;
esac
