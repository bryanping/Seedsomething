#!/usr/bin/env bash
set -euo pipefail

TASK="${1:-}"
if [ -z "$TASK" ]; then
  echo '用法：./scripts/ai_dev.sh "任務描述"'
  exit 1
fi

ROOT="/Users/openaiplanner/sandbox/openclaw/Seedsomething"
cd "$ROOT"

PROMPT="$(cat <<'PROMPT_EOF'
你是 Seedsomething 專案的 iOS/SwiftUI 工程代理。

【必讀檔案】
- /Users/openaiplanner/sandbox/openclaw/Seedsomething/.openclaw/AGENT_SYSTEM.md
- /Users/openaiplanner/sandbox/openclaw/Seedsomething/.openclaw/PROJECT_CONTEXT.md
- /Users/openaiplanner/sandbox/openclaw/Seedsomething/.openclaw/WORKFLOW.md
- /Users/openaiplanner/sandbox/openclaw/Seedsomething/.openclaw/checklists/IOS_BUILD_CHECKLIST.md
- /Users/openaiplanner/sandbox/openclaw/Seedsomething/.openclaw/memory/ARCHITECTURE.md
- /Users/openaiplanner/sandbox/openclaw/Seedsomething/.openclaw/memory/DECISIONS.md

【工作目錄】
/Users/openaiplanner/sandbox/openclaw/Seedsomething

【硬性要求】
1) 先用 shell 在 repo 內搜尋/定位相關檔案（不得猜檔名/路徑）
2) 修改必須小步
3) 修改後必須跑：/Users/openaiplanner/sandbox/openclaw/Seedsomething/scripts/ai_verify.sh
4) 若 verify 因 simulator 名稱失敗，改用：/Users/openaiplanner/sandbox/openclaw/Seedsomething/scripts/ai_build.sh
5) 最終輸出必須包含：
   - 修改檔案清單
   - 每檔改動摘要
   - 驗證結果（OK/FAIL）
   - git diff 重點區塊（只貼關鍵，不要全貼）

【任務】
__TASK_PLACEHOLDER__
PROMPT_EOF
)"

export PROMPT_IN="$PROMPT"
export TASK_IN="$TASK"
PROMPT="$(python3 - <<'PY'
import os
prompt=os.environ["PROMPT_IN"]
task=os.environ["TASK_IN"]
print(prompt.replace("__TASK_PLACEHOLDER__", task))
PY
)"
# //修改内容：确保 main agent 存在
openclaw agents list | rg -q '^- main ' || { echo "❌ openclaw agent main 不存在"; exit 2; }

echo "== Run agent =="
openclaw agent --agent main -m "$PROMPT"  # //修改内容：固定 agent=main，避免 session/timeout 問題

echo "== Verify/build gate =="
BUILD_OK=0  # //修改内容：只有成功才 commit

echo "== Local verify (preferred) =="
if [ -x "$ROOT/scripts/ai_verify.sh" ]; then
  if "$ROOT/scripts/ai_verify.sh"; then
    BUILD_OK=1
  else
    echo "verify failed -> fallback build"
  fi
fi

echo "== Fallback build (iPhone 16) =="
if [ "$BUILD_OK" -eq 0 ] && [ -x "$ROOT/scripts/ai_build.sh" ]; then
  if "$ROOT/scripts/ai_build.sh"; then
    BUILD_OK=1
  fi
fi

if [ "$BUILD_OK" -eq 0 ]; then
  echo "❌ verify/build 全部失敗，不 commit"
  git status || true
  exit 1  # //修改内容：失敗就停止，避免污染歷史
fi

echo "✅ BUILD OK"

echo "== Auto commit =="
# //修改内容：只 commit 追蹤檔案（避免把 .openclaw 一次全塞進 repo）
git add -A :/  # 只對 repo 內追蹤/新增變更做 stage
git commit -m "AI auto dev: $TASK" || echo "No changes to commit"

echo "== Done =="
git status || true