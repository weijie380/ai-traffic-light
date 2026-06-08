#!/bin/bash
# 🚦 Reasonix + AI Traffic Light 集成 Hook
# 被 Reasonix config.json 的 hooks 调用
# 同时更新 Claude Pet 状态 + 红绿灯

STATE="${1:-idle}"
CLAUDE_HOOK="/Users/weijie/Applications/ClaudePet.app/Contents/Resources/hooks/reasonix-hooks/reasonix-hook.sh"

# 1. 调用原有的 Claude Pet hook（如果存在）
if [ -f "$CLAUDE_HOOK" ]; then
    bash "$CLAUDE_HOOK" "$STATE" 2>/dev/null &
fi

# 2. 更新红绿灯
TRAFFIC_LIGHT="/Library/code/pycharmcode/ai-traffic-light/scripts/reasonix-integration.sh"

case "$STATE" in
    running|thinking)
        bash "$TRAFFIC_LIGHT" start "Reasonix" "运行中"
        ;;
    requesting)
        bash "$TRAFFIC_LIGHT" permission "Reasonix" "等待授权"
        ;;
    completed)
        bash "$TRAFFIC_LIGHT" end "Reasonix" "已完成"
        ;;
    error)
        bash "$TRAFFIC_LIGHT" error "Reasonix" "遇到错误"
        ;;
esac
