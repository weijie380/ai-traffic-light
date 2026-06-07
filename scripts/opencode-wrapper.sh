#!/bin/bash
# 🚦 OpenCode wrapper
# 安装: echo 'alias opencode="/path/to/opencode-wrapper.sh"' >> ~/.zshrc

STATUS_FILE="/Library/code/pycharmcode/ai-traffic-light/.ai-traffic-light/status.json"

# 找到真实的 opencode
OPENCODE_BIN=""
for p in ~/.opencode/bin/opencode /usr/local/bin/opencode /opt/homebrew/bin/opencode; do
    [ -x "$p" ] && OPENCODE_BIN="$p" && break
done
[ -z "$OPENCODE_BIN" ] && { echo "❌ 找不到 opencode"; exit 1; }

# 🟢 绿灯
python3 <<PYEOF
import json, time
with open("$STATUS_FILE", "r") as f:
    try: old = json.load(f)
    except: old = {}
tc = old.get("transition_count", 0) + 1
with open("$STATUS_FILE", "w") as f:
    json.dump({
        "status": "working", "signal": "working",
        "tool": "OpenCode", "message": "运行中",
        "emoji": "🟢", "pattern": "pulse-green",
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "heartbeat": int(time.time()),
        "transition_count": tc,
    }, f, indent=2)
PYEOF

# 执行 opencode
"$OPENCODE_BIN" "$@"
EXIT_CODE=$?

# 🟡 完成 / 🔴 错误
if [ $EXIT_CODE -ne 0 ]; then
python3 <<PYEOF
import json, time
with open("$STATUS_FILE", "r") as f:
    try: old = json.load(f)
    except: old = {}
tc = old.get("transition_count", 0) + 1
with open("$STATUS_FILE", "w") as f:
    json.dump({
        "status": "waiting", "signal": "waiting",
        "tool": "OpenCode", "message": "需要处理 (exit: $EXIT_CODE)",
        "emoji": "🔴", "pattern": "pulse-red",
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "heartbeat": int(time.time()),
        "transition_count": tc,
    }, f, indent=2)
PYEOF
else
python3 <<PYEOF
import json, time
with open("$STATUS_FILE", "r") as f:
    try: old = json.load(f)
    except: old = {}
tc = old.get("transition_count", 0) + 1
with open("$STATUS_FILE", "w") as f:
    json.dump({
        "status": "completed", "signal": "completed",
        "tool": "", "message": "OpenCode 完成",
        "emoji": "🟡", "pattern": "pulse-yellow",
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "heartbeat": int(time.time()),
        "transition_count": tc,
    }, f, indent=2)
PYEOF
fi

exit $EXIT_CODE
