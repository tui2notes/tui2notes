#!/usr/bin/env bash
# Compile the menu-bar agent into a .app bundle.
#   ./agent/build.sh [output-dir]      (default: /Applications)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-/Applications}"
APP="$OUT/tui2notes.app"

command -v swiftc >/dev/null || { echo "swiftc not found (install Xcode Command Line Tools)"; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -o "$APP/Contents/MacOS/tui2notes" agent/main.swift -framework Cocoa

# App icon: the menu-bar table glyph on a plate. Skipped if rendering fails,
# in which case the app simply gets the generic bundle icon.
ICON=""
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
if swift agent/makeicon.swift "$WORK/tui2notes.iconset" 2>/dev/null &&
   iconutil -c icns -o "$APP/Contents/Resources/tui2notes.icns" "$WORK/tui2notes.iconset" 2>/dev/null; then
  ICON='  <key>CFBundleIconFile</key><string>tui2notes</string>'
else
  echo "warning: could not render app icon" >&2
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>tui2notes</string>
  <key>CFBundleDisplayName</key><string>tui2notes</string>
  <key>CFBundleIdentifier</key><string>com.thomaslwang.tui2notes</string>
  <key>CFBundleExecutable</key><string>tui2notes</string>
$ICON
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "built $APP"
