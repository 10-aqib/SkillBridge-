#!/usr/bin/env bash
# Captures screenshots with headless Chrome.
# Usage: design/tools/capture.sh <page> <out.png> <width> <height> [out-folder-under-design]
#   <page> is a prototype file (served by: npx http-server@14.1.1 design/prototypes -p 4173)
#   or a full http(s) URL such as the running Flutter web app or admin console.
#   BUDGET=<ms> env var sets how long the page may load (default 8000).
set -euo pipefail
CHROME="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/${5:-prototypes/screenshots}"
URL="$1"
case "$URL" in http*) ;; *) URL="http://localhost:4173/$1" ;; esac
mkdir -p "$OUT_DIR"
PROFILE="$(mktemp -d)"
# SCHEME=light|dark emulates the OS colour preference (default light).
if [ "${SCHEME:-light}" = dark ]; then PREF=0; else PREF=1; fi
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --blink-settings=preferredColorScheme=$PREF \
  --user-data-dir="$PROFILE" --virtual-time-budget="${BUDGET:-8000}" \
  --window-size="$3,$4" --screenshot="$(cygpath -w "$OUT_DIR/$2")" "$URL" >/dev/null 2>&1 || true
rm -rf "$PROFILE"
ls -la "$OUT_DIR/$2"
