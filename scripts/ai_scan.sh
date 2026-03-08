#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TASK="${1:-掃描專案}"

echo "== AI SCAN =="
echo "TASK: $TASK"

echo
echo "---- 專案入口 ----"

rg -n "@main|RootView|HomeView|App" Seedsomething || true

echo
echo "---- Swift Files ----"

find Seedsomething -name "*.swift" | head -n 30
