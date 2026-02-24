#!/usr/bin/env bash
set -euo pipefail

PROJECT="Seedsomething.xcodeproj"
SCHEME="Seedsomething"

# 修改内容：改成你机器上存在的模拟器（从 xcodebuild 输出可见 iPhone 16）
DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=18.4"

echo "==> Xcode: $(xcodebuild -version | tr '\n' ' ')"
echo "==> Project: $PROJECT"
echo "==> Scheme:  $SCHEME"
echo "==> Dest:    $DESTINATION"
echo ""

echo "==> Resolve Package Dependencies"
xcodebuild -resolvePackageDependencies -project "$PROJECT"

echo ""
echo "==> Build (Simulator)"
BUILD_LOG="$(mktemp)"

set +e
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" build 2>&1 | tee "$BUILD_LOG"
BUILD_EXIT=${PIPESTATUS[0]}
set -e

if [ $BUILD_EXIT -ne 0 ]; then
  echo ""
  echo "❌ BUILD FAILED. Key errors:"
  # 修改内容：用更稳的错误提取，避免 grep 正则在 macOS 上报错
  egrep -n "error:|fatal error:|BUILD FAILED|Unable to find a device matching" "$BUILD_LOG" | tail -n 80 || true
  exit $BUILD_EXIT
fi

echo ""
echo "✅ BUILD OK"
