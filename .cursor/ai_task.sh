#!/usr/bin/env bash
set -euo pipefail

TASK="${1:-}"
if [ -z "$TASK" ]; then
  echo '用法：./.cursor/ai_task.sh "任務描述"'
  exit 1
fi

ROOT="/Users/openaiplanner/sandbox/openclaw/Seedsomething"
cd "$ROOT"

./scripts/ai_dev.sh "$TASK"
