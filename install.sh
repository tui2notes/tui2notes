#!/usr/bin/env bash
# Install tui2notes.
#
#   ./install.sh                CLI + menu-bar agent + start it at login
#   ./install.sh --no-agent     CLI only
#   ./install.sh --applet       also build the click-to-paste applet
#   PREFIX=/usr/local ./install.sh
set -euo pipefail
cd "$(dirname "$0")"

[ "$(uname)" = "Darwin" ] || { echo "tui2notes is macOS-only."; exit 1; }

PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin/tui2notes"
LABEL="com.thomaslwang.tui2notes"
want_agent=1; want_applet=0
for a in "$@"; do
  case "$a" in
    --no-agent) want_agent=0 ;;
    --applet)   want_applet=1 ;;
    *) echo "unknown option: $a"; exit 1 ;;
  esac
done

mkdir -p "$PREFIX/bin"
install -m 755 bin/tui2notes "$BIN"
echo "installed $BIN"
case ":$PATH:" in *":$PREFIX/bin:"*) ;; *) echo "note: $PREFIX/bin is not on your PATH" ;; esac

if [ "$want_agent" = 1 ]; then
  APPDIR=/Applications
  [ -w "$APPDIR" ] || { APPDIR="$HOME/Applications"; mkdir -p "$APPDIR"; }
  launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
  pkill -f "$APPDIR/tui2notes.app/Contents/MacOS" 2>/dev/null || true
  ./agent/build.sh "$APPDIR"

  mkdir -p "$HOME/Library/LaunchAgents"
  sed "s|/Applications/tui2notes.app|$APPDIR/tui2notes.app|" \
      "agent/$LABEL.plist" > "$HOME/Library/LaunchAgents/$LABEL.plist"
  launchctl bootstrap "gui/$UID" "$HOME/Library/LaunchAgents/$LABEL.plist"
  echo "menu-bar agent running, and set to start at login"
fi

if [ "$want_applet" = 1 ]; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  sed "s|__TUI2NOTES_BIN__|$BIN|" app/tui2notes.applescript > "$tmp/a.applescript"
  rm -rf "$HOME/Applications/tui2notes-paste.app"
  mkdir -p "$HOME/Applications"
  osacompile -o "$HOME/Applications/tui2notes-paste.app" "$tmp/a.applescript"
  echo "installed ~/Applications/tui2notes-paste.app (needs Accessibility to paste)"
fi
