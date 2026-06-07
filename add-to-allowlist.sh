#!/bin/bash
# 🚦 将 AI Traffic Light 的 status 命令加入 Reasonix 白名单
# 这样红绿灯状态更新就能自动执行，不需要手动批准

CONFIG="$HOME/.reasonix/config.json"
PROJECT="/Library/code/pycharmcode"
NEW_RULE="python3 /Library/code/pycharmcode/ai-traffic-light/status"

python3 -c "
import json

with open('$CONFIG', 'r') as f:
    cfg = json.load(f)

allowed = cfg.get('projects', {}).get('$PROJECT', {}).get('shellAllowed', [])
if '$NEW_RULE' not in allowed:
    allowed.append('$NEW_RULE')
    cfg['projects']['$PROJECT']['shellAllowed'] = allowed
    
    with open('$CONFIG', 'w') as f:
        json.dump(cfg, f, indent=2)
    print('✅ 已添加白名单规则: $NEW_RULE')
    print('   现在红绿灯状态更新将自动执行，无需手动批准！')
else:
    print('ℹ️ 白名单规则已存在，无需重复添加')
"