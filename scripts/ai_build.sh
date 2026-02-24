#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/openaiplanner/sandbox/openclaw/Seedsomething"
cd "$ROOT"

echo "== Build (iPhone 16) =="
xcodebuild -project Seedsomething.xcodeproj \
  -scheme Seedsomething \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
