#!/usr/bin/env bash
# Install the tui2notes CLI and (optionally) the clickable app.
#
#   ./install.sh              -> CLI into ~/.local/bin, app into /Applications
#   PREFIX=/usr/local ./install.sh
#   APPDIR=~/Applications ./install.sh
#   ./install.sh --no-app     -> CLI only
set -euo pipefail
cd "$(dirname "$0")"

[ "$(uname)" = "Darwin" ] || { echo "tui2notes is macOS-only (needs textutil, pbpaste, osascript)."; exit 1; }

PREFIX="${PREFIX:-$HOME/.local}"
APPDIR="${APPDIR:-/Applications}"
BIN="$PREFIX/bin/tui2notes"

mkdir -p "$PREFIX/bin"
install -m 755 bin/tui2notes "$BIN"
echo "installed $BIN"
case ":$PATH:" in
  *":$PREFIX/bin:"*) ;;
  *) echo "note: $PREFIX/bin is not on your PATH" ;;
esac

if [ "${1:-}" = "--no-app" ]; then exit 0; fi

command -v osacompile >/dev/null || { echo "osacompile not found; skipping the app."; exit 0; }
[ -w "$APPDIR" ] || { echo "note: $APPDIR is not writable, using ~/Applications"; APPDIR="$HOME/Applications"; mkdir -p "$APPDIR"; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
sed "s|__TUI2NOTES_BIN__|$BIN|" app/tui2notes.applescript > "$tmp/tui2notes.applescript"
rm -rf "$APPDIR/tui2notes.app"
osacompile -o "$APPDIR/tui2notes.app" "$tmp/tui2notes.applescript"
echo "installed $APPDIR/tui2notes.app  (drag it to the Dock)"
echo
echo "First click will ask for permissions. Without Accessibility it still"
echo "works - it creates a new note instead of pasting at the cursor."
