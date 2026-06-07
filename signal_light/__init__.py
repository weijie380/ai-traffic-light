"""Signal patterns for AI Traffic Light."""

STATUS_DIR = None  # set by cli.py on startup

SIGNALS = {
    "idle":       {"status": "idle",      "label": "空闲",   "emoji": "⚫", "pattern": "off"},
    "working":    {"status": "working",   "label": "运行中", "emoji": "🟢", "pattern": "pulse-green"},
    "waiting":    {"status": "waiting",   "label": "等待授权","emoji": "🔴", "pattern": "pulse-red"},
    "completed":  {"status": "completed", "label": "已完成", "emoji": "🟡", "pattern": "pulse-yellow"},
    "blocked":    {"status": "waiting",   "label": "阻塞",   "emoji": "🔴", "pattern": "flash-red"},
    "attention":  {"status": "waiting",   "label": "需关注", "emoji": "🔴", "pattern": "pulse-red"},
}

# Priority: higher number = higher priority
PRIORITY = {
    "blocked": 5,
    "waiting": 4,
    "attention": 3,
    "working": 2,
    "completed": 1,
    "idle": 0,
}

# Event → signal mapping for AI tool hooks
# Matches the reference project's event mapping
EVENT_MAP = {
    # Claude Code events
    "SessionStart": "idle",
    "UserPromptSubmit": "working",
    "PreToolUse": "working",
    "PostToolUse": "working",
    "PostToolUseFailure": "blocked",
    "PermissionRequest": "waiting",
    "Notification": "attention",
    "Stop": "idle",
    "SessionEnd": "completed",
    # Generic events
    "onTaskStart": "working",
    "onTaskEnd": "completed",
    "onError": "blocked",
}
