#!/bin/bash
# 🚦 AI Traffic Light — 一键配置 OpenCode 和 Reasonix 集成
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS_SCRIPT="$ROOT_DIR/signal_light/__main__.py"

echo ""
echo "  🚦  AI Traffic Light — 配置工具"
echo "  ═══════════════════════════════"
echo ""

# 1. 配置 OpenCode alias
echo "  📎 配置 OpenCode alias..."
OPENCODE_ALIAS="alias opencode=\"$ROOT_DIR/scripts/opencode-wrapper.sh\""

# 检查是否已配置
if grep -q "opencode-wrapper.sh" ~/.zshrc 2>/dev/null || grep -q "opencode-wrapper.sh" ~/.bashrc 2>/dev/null; then
    echo "     ✅ OpenCode alias 已配置"
else
    # 添加到 shell 配置
    for shell_config in ~/.zshrc ~/.bashrc ~/.bash_profile; do
        if [ -f "$shell_config" ]; then
            echo "" >> "$shell_config"
            echo "# 🚦 AI Traffic Light — OpenCode 集成" >> "$shell_config"
            echo "$OPENCODE_ALIAS" >> "$shell_config"
            echo "     → 已添加到 $shell_config"
            break
        fi
    done
    echo "     ⚠️  请重新加载 shell: source ~/.zshrc"
fi

# 2. 配置 Reasonix 集成
echo ""
echo "  🔧 配置 Reasonix 集成..."
REASONIX_SCRIPT="$ROOT_DIR/scripts/reasonix-integration.sh"

# 创建 Reasonix 配置目录
REASONIX_CONFIG_DIR="$HOME/.reasonix"
mkdir -p "$REASONIX_CONFIG_DIR"

# 创建示例配置
cat > "$REASONIX_CONFIG_DIR/traffic-light-example.sh" << 'EOF'
#!/bin/bash
# 🚦 Reasonix + AI Traffic Light 集成示例
# 在 Reasonix 的代码中调用此脚本

TRAFFIC_LIGHT_SCRIPT="/Library/code/pycharmcode/ai-traffic-light/scripts/reasonix-integration.sh"

# 任务开始
$TRAFFIC_LIGHT_SCRIPT start "Reasonix" "正在分析代码"

# ... 你的任务逻辑 ...

# 任务完成
$TRAFFIC_LIGHT_SCRIPT end "Reasonix" "代码重构完成"
EOF

chmod +x "$REASONIX_CONFIG_DIR/traffic-light-example.sh"
echo "     → 示例配置: $REASONIX_CONFIG_DIR/traffic-light-example.sh"

# 3. 设置脚本权限
echo ""
echo "  🔑 设置脚本权限..."
chmod +x "$ROOT_DIR/scripts/opencode-wrapper.sh"
chmod +x "$ROOT_DIR/scripts/reasonix-integration.sh"
chmod +x "$ROOT_DIR/scripts/claude-hook"
chmod +x "$ROOT_DIR/scripts/install.sh"
echo "     ✅ 所有脚本已设置为可执行"

# 4. 测试集成
echo ""
echo "  🧪 测试集成..."
echo "     测试 OpenCode wrapper..."
if [ -x "$ROOT_DIR/scripts/opencode-wrapper.sh" ]; then
    echo "     ✅ OpenCode wrapper 脚本可执行"
else
    echo "     ❌ OpenCode wrapper 脚本不可执行"
fi

echo "     测试 Reasonix integration..."
if [ -x "$ROOT_DIR/scripts/reasonix-integration.sh" ]; then
    echo "     ✅ Reasonix 集成脚本可执行"
else
    echo "     ❌ Reasonix 集成脚本不可执行"
fi

# 5. 初始化状态文件
echo ""
echo "  📊 初始化状态文件..."
STATUS_FILE="$ROOT_DIR/.ai-traffic-light/status.json"
if [ ! -f "$STATUS_FILE" ]; then
    mkdir -p "$(dirname "$STATUS_FILE")"
    cat > "$STATUS_FILE" <<EOF
{
  "status": "idle",
  "signal": "idle",
  "tool": "",
  "message": "空闲",
  "emoji": "⚫",
  "pattern": "off",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "heartbeat": $(date +%s),
  "transition_count": 0
}
EOF
    echo "     → 创建状态文件: $STATUS_FILE"
else
    echo "     ✅ 状态文件已存在"
fi

echo ""
echo "  ✅ 配置完成！"
echo ""
echo "  📋 使用方法："
echo ""
echo "  OpenCode:"
echo "    1. 重新加载 shell: source ~/.zshrc"
echo "    2. 运行: opencode"
echo "    3. 红绿灯会自动显示状态变化"
echo ""
echo "  Reasonix:"
echo "    在你的代码中调用："
echo "      $REASONIX_SCRIPT start \"Reasonix\" \"任务描述\""
echo "      $REASONIX_SCRIPT end \"Reasonix\" \"完成描述\""
echo ""
echo "  🌐 启动 Web UI（可选）："
echo "    python3 -m signal_light serve"
echo "    访问: http://localhost:19876"
echo ""
