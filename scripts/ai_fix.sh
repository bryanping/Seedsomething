#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== AI FIX MODE =="
echo "嘗試修復 build 錯誤"

./scripts/ai_loop.sh "修復目前 build 錯誤直到 verify 成功"
