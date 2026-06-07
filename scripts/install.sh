#!/bin/bash
# 🚦 安装 AI Traffic Light 集成
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS_SCRIPT="$ROOT_DIR/signal_light/__main__.py"
HOOK_SCRIPT="$ROOT_DIR/scripts/claude-hook"
CLI_SCRIPT="$ROOT_DIR/scripts/signal-light"

echo ""
echo "  🚦  AI Traffic Light — 安装"
echo "  ═══════════════════════════"
echo ""

# 1. 安装 signal-light 命令
echo "  📎 安装 signal-light 命令..."
for bin_dir in /usr/local/bin "$HOME/.local/bin"; do
    if [ -d "$bin_dir" ] && [ -w "$bin_dir" ]; then
        cp "$CLI_SCRIPT" "$bin_dir/signal-light"
        chmod +x "$bin_dir/signal-light"
        echo "     → $bin_dir/signal-light"
        break
    fi
done

# 创建 alias 提示
echo "     也可用: alias signal-light='python3 $CLI_SCRIPT'"

# 2. 创建 Claude Code hooks 配置
echo ""
echo "  🤖 安装 Claude Code hooks..."
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
    # 备份
    cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak.$(date +%s)" 2>/dev/null || true
    
    python3 << PYEOF
import json, os

path = "$CLAUDE_SETTINGS"
hook_script = "$HOOK_SCRIPT"

try:
    with open(path, 'r') as f:
        s = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    s = {}

# Add hooks section
if 'hooks' not in s:
    s['hooks'] = {}

s['hooks']['onTaskStart'] = f'python3 {hook_script} onTaskStart --tool "Claude Code"'
s['hooks']['onTaskEnd'] = f'python3 {hook_script} onTaskEnd --tool "Claude Code"'
s['hooks']['onError'] = f'python3 {hook_script} onError --tool "Claude Code"'
s['hooks']['onPermissionRequest'] = f'python3 {hook_script} onPermissionRequest --tool "Claude Code"'

with open(path, 'w') as f:
    json.dump(s, f, indent=2)
print("     ✓ Claude Code hooks 已安装")
PYEOF
else
    echo "     ⚠ 未找到 ~/.claude/settings.json"
    echo "     请手动创建并添加 hooks 配置"
fi

# 3. 创建启动脚本
echo ""
echo "  🚀 创建启动脚本..."
cat > "$ROOT_DIR/start.command" << CMD
#!/bin/bash
cd "$ROOT_DIR"
echo "🚦 AI Traffic Light 启动中..."
python3 -m signal_light serve &
sleep 2
# 启动菜单栏
if [ -f "$ROOT_DIR/Traffic Light.app" ]; then
    open "$ROOT_DIR/Traffic Light.app"
fi
echo "🌐 http://localhost:19876"
wait
CMD
chmod +x "$ROOT_DIR/start.command"

echo "     → $ROOT_DIR/start.command"

# 4. 设置初始状态
echo ""
echo "  ⚪ 设置初始状态..."
python3 -m signal_light play idle 2>/dev/null || true

echo ""
echo "  ✅ 安装完成"
echo ""
echo "  📋 用法:"
echo "    signal-light play working      🟢 运行中"
echo "    signal-light play waiting      🔴 等待确认"
echo "    signal-light play completed    🟡 已完成"
echo "    signal-light play idle         ⚫ 空闲"
echo "    signal-light list              列出所有信号"
echo "    signal-light serve             启动 Web 服务器"
echo ""
echo "  🌐 浏览器: http://localhost:19876"
echo "  🖱  双击: start.command"
echo ""