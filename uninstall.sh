#!/usr/bin/env bash
set -euo pipefail
PREFIX="${PREFIX:-$HOME/.local}"
rm -f  "$PREFIX/bin/tui2notes"        && echo "removed $PREFIX/bin/tui2notes"
rm -rf /Applications/tui2notes.app "$HOME/Applications/tui2notes.app"
rm -rf "$HOME/Library/Services/tui2notes.workflow" \
       "$HOME/Library/Services/tui2notes-paste.workflow"
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
echo "done"
