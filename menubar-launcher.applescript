-- This script acts as a proper macOS application that can show in menu bar
-- It just launches the Swift menubar binary with GUI access

do shell script "pkill -9 -f ai-traffic-light-menubar 2>/dev/null; sleep 1"
do shell script "/Library/code/pycharmcode/ai-traffic-light/ai-traffic-light-menubar &"
