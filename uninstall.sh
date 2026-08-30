#!/usr/bin/env bash
set -euo pipefail
PREFIX="${PREFIX:-$HOME/.local}"
LABEL="com.thomaslwang.tui2notes"
launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
rm -f  "$HOME/Library/LaunchAgents/$LABEL.plist"
pkill -f 'tui2notes.app/Contents/MacOS' 2>/dev/null || true
rm -rf /Applications/tui2notes.app "$HOME/Applications/tui2notes.app" \
       "$HOME/Applications/tui2notes-paste.app"
rm -f  "$PREFIX/bin/tui2notes"
rm -rf "$HOME/Library/Services/tui2notes.workflow" \
       "$HOME/Library/Services/tui2notes-paste.workflow"
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
echo "removed"
