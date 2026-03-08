#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/openaiplanner/sandbox/openclaw/Seedsomething"
cd "$ROOT"

TASK="${1:-}"
if [ -z "$TASK" ]; then
  echo '用法：./scripts/ai_loop.sh "任務描述"'
  exit 1
fi

MAX_ROUNDS="${MAX_ROUNDS:-8}"   # 最多自動修 8 輪
SLEEP_SEC="${SLEEP_SEC:-1}"

echo "== AI LOOP START =="
echo "TASK: $TASK"
echo "MAX_ROUNDS: $MAX_ROUNDS"
echo

# 1) 固定使用 main agent（你已確認存在）
openclaw agents list | rg -q '^- main ' || { echo "❌ openclaw agent main 不存在"; exit 2; }

# 2) 每輪：build -> 若失敗抽錯誤 -> 交給 agent 修 -> 繼續
round=1
while [ "$round" -le "$MAX_ROUNDS" ]; do
  echo "=============================="
  echo "== Round $round / $MAX_ROUNDS"
  echo "=============================="

  echo "== Build =="
  set +e
  ./scripts/ai_verify.sh > /tmp/ai_verify.log 2>&1
  code=$?
  set -e

  if [ "$code" -eq 0 ]; then
    echo "✅ BUILD OK (verify)"
    break
  fi

  echo "❌ BUILD FAIL (verify). Extracting errors..."
  # 抽「真正的錯誤行」給 agent（避免它瞎修）
  ERR="$(rg -n 'error:|錯誤：|fatal error|BUILD FAILED|SwiftCompile|Ld ' /tmp/ai_verify.log | head -n 120 || true)"
  echo "$ERR" > /tmp/ai_errors.txt

  # 如果 verify 是 simulator 名稱問題，直接 fallback build
  if rg -q "Unable to find a device matching" /tmp/ai_verify.log; then
    echo "== Fallback build (iPhone 16) =="
    set +e
    ./scripts/ai_build.sh > /tmp/ai_build.log 2>&1
    code2=$?
    set -e
    if [ "$code2" -eq 0 ]; then
      echo "✅ BUILD OK (fallback)"
      break
    fi
    ERR="$(rg -n 'error:|錯誤：|fatal error|BUILD FAILED|SwiftCompile|Ld ' /tmp/ai_build.log | head -n 160 || true)"
    echo "$ERR" > /tmp/ai_errors.txt
  fi

  echo "== Run agent to fix =="
  PROMPT="$(cat <<PROMPT_EOF
你是 Seedsomething 專案的 iOS/SwiftUI 工程代理。

目標：修到 Xcode build OK（優先修編譯錯誤），修改要最小化。
規則：
1) 必須先用 shell 在 repo 內搜尋定位檔案（不得猜檔名/路徑）
2) 每次只做最小修復（能改1檔不改2檔）
3) 修完必跑：$ROOT/scripts/ai_verify.sh（失敗再跑 $ROOT/scripts/ai_build.sh）
4) build OK 才能進入 commit
5) 輸出：修改檔案清單、每檔摘要、驗證結果、git diff 重點（只貼關鍵）

【任務】
$TASK

【本輪 build 關鍵錯誤摘要（請以此為準）】
$(cat /tmp/ai_errors.txt)

PROMPT_EOF
)"

  # ⚠️ 這裡固定用 main agent
  openclaw agent --agent main -m "$PROMPT" || true

  sleep "$SLEEP_SEC"
  round=$((round+1))
done

echo
echo "== Final status =="
git status || true

# 3) 成功才 commit
set +e
./scripts/ai_verify.sh >/dev/null 2>&1
ok=$?
set -e

if [ "$ok" -eq 0 ]; then
  echo "== Auto commit =="
  git add .
  git commit -m "AI loop: $TASK" || echo "No changes"
else
  echo "❌ verify/build 全部失敗，不 commit"
  exit 3
fi

echo "== AI LOOP DONE =="
