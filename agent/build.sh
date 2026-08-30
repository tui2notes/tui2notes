#!/usr/bin/env bash
# Compile the menu-bar agent into a .app bundle.
#   ./agent/build.sh [output-dir]      (default: /Applications)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-/Applications}"
APP="$OUT/tui2notes.app"

command -v swiftc >/dev/null || { echo "swiftc not found (install Xcode Command Line Tools)"; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -o "$APP/Contents/MacOS/tui2notes" agent/main.swift -framework Cocoa

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>tui2notes</string>
  <key>CFBundleDisplayName</key><string>tui2notes</string>
  <key>CFBundleIdentifier</key><string>com.thomaslwang.tui2notes</string>
  <key>CFBundleExecutable</key><string>tui2notes</string>
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
