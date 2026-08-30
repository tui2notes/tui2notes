#!/usr/bin/env bash
# Offline tests: exercise the parser only (no clipboard, no GUI).
set -u
cd "$(dirname "$0")/.."
BIN="python3 bin/tui2notes"
fail=0

check() { # check <name> <expected-substring> <<< html
  local name=$1 needle=$2 html
  html=$(cat)
  if grep -qF -- "$needle" <<<"$html"; then
    echo "  ok   $name"
  else
    echo "  FAIL $name — expected to find: $needle"; fail=1
  fi
}

echo "box-drawing table:"
$BIN --html < examples/box-table.txt > /tmp/tui2notes-box.html
# wrapped cell content must be re-joined into one sentence
check "wrapped cell rejoined" \
  "ok — 214 tests passed, 0 skipped, and coverage held at 91%" \
  < /tmp/tui2notes-box.html
check "header cell" "<th" < /tmp/tui2notes-box.html
check "three columns" "<th style=\"border:1px solid #b0b0b0;background:#f0f0f0;text-align:left;\">time</th>" \
  < /tmp/tui2notes-box.html
[ "$(grep -o '<table' /tmp/tui2notes-box.html | wc -l | tr -d ' ')" = 1 ] \
  && echo "  ok   exactly one table" || { echo "  FAIL table count"; fail=1; }

echo "markdown table:"
$BIN --html < examples/markdown-table.md > /tmp/tui2notes-md.html
check "row parsed" "2026-05-04" < /tmp/tui2notes-md.html
check "bold inline" "<b>native tables</b>" < /tmp/tui2notes-md.html
check "code inline" "<code" < /tmp/tui2notes-md.html
check "heading" "<h1>Release notes</h1>" < /tmp/tui2notes-md.html

echo "CJK line-join heuristic:"
# A cell wrapped mid-number and mid-sentence: digits glue to the following
# CJK unit, CJK glues to CJK, and a latin word keeps its space.
cat > /tmp/tui2notes-cjk.txt <<'TBL'
┌───────────────┐
│ payload      │
├───────────────┤
│ 24.7         │
│ KiB/行（26.4  │
│ 万行）       │
└───────────────┘
TBL
$BIN --html < /tmp/tui2notes-cjk.txt > /tmp/tui2notes-cjk.html
check "digit+CJK joins tight, latin keeps space" \
  "24.7 KiB/行（26.4万行）" < /tmp/tui2notes-cjk.html

echo "already-RTF guard:"
out=$(printf '{\\rtf1\\ansi hello}' | $BIN 2>&1)
grep -q "already rich text" <<<"$out" && echo "  ok   guard fires" \
  || { echo "  FAIL guard: $out"; fail=1; }

[ $fail = 0 ] && echo "ALL PASS" || echo "FAILURES"
exit $fail
