#!/bin/bash
cd "/Library/code/pycharmcode/ai-traffic-light"

# Start server if not running
if ! curl -s http://127.0.0.1:19876/state > /dev/null 2>&1; then
    echo "🚦 启动 AI Traffic Light..."
    python3 server.py --no-browser &
    sleep 2
fi

# Start menubar
if ! pgrep -f "ai-traffic-light-menubar" > /dev/null 2>&1; then
    ./ai-traffic-light-menubar &
fi

# Open browser
open http://127.0.0.1:19876
echo "✅ 启动完成"
