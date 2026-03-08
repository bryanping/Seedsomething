#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/openaiplanner/sandbox/openclaw/Seedsomething"
cd "$ROOT"

MAX_ROUNDS="${MAX_ROUNDS:-4}"          # 最多自動修復輪數
TASK_PREFIX="${TASK_PREFIX:-AutoFix}"  # commit 訊息前綴
VERIFY_SCRIPT="${VERIFY_SCRIPT:-$ROOT/scripts/ai_verify.sh}"
BUILD_SCRIPT="${BUILD_SCRIPT:-$ROOT/scripts/ai_build.sh}"  # iPhone 16 fallback build

LOG_DIR="${LOG_DIR:-$ROOT/.openclaw/logs}"
mkdir -p "$LOG_DIR"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "❌ 缺少命令：$1"; exit 2; }
}

require_cmd openclaw
require_cmd rg
require_cmd git

# 檢查 main agent 是否存在（避免 openclaw agent 報不清楚的錯）
openclaw agents list | rg -q '^- main ' || { echo "❌ openclaw agent main 不存在"; exit 2; }

# 你要 build 用 verify（可能會因 simulator 名稱失敗），失敗再走 build.sh
run_build_once() {
  local out="$1"
  local ok=0

  echo "== Build via ai_verify.sh ==" | tee "$out"
  if [ -x "$VERIFY_SCRIPT" ]; then
    set +e
    "$VERIFY_SCRIPT" 2>&1 | tee -a "$out"
    ok="${PIPESTATUS[0]}"
    set -e
    if [ "$ok" -eq 0 ]; then return 0; fi
  else
    echo "⚠️ 找不到 $VERIFY_SCRIPT" | tee -a "$out"
  fi

  echo "== Fallback build via ai_build.sh (iPhone 16) ==" | tee -a "$out"
  if [ -x "$BUILD_SCRIPT" ]; then
    set +e
    "$BUILD_SCRIPT" 2>&1 | tee -a "$out"
    ok="${PIPESTATUS[0]}"
    set -e
    if [ "$ok" -eq 0 ]; then return 0; fi
  else
    echo "⚠️ 找不到 $BUILD_SCRIPT" | tee -a "$out"
  fi

  return 1
}

# 從 build log 抽取可用的錯誤片段（越短越好，但要可定位檔案）
extract_errors() {
  local log="$1"

  # 1) 最常見 Swift 編譯錯誤：/path/file.swift:line:col: error: ...
  # 2) Xcode 也會用「錯誤：」中文，保守抓 "error:" + "錯誤："
  # 3) 再抓 "BUILD FAILED" 區塊尾巴，提供上下文
  {
    echo "=== ERROR_LINES (file:line:col) ==="
    rg -n --no-heading -S ':\d+:\d+:\s*(error:|錯誤：)' "$log" | head -n 40 || true

    echo
    echo "=== KEY_ERRORS (generic) ==="
    rg -n --no-heading -S '(error:|錯誤：)|\*\* BUILD FAILED \*\*|BUILD FAILED|Command SwiftCompile|SwiftCompile' "$log" | head -n 80 || true

    echo
    echo "=== LOG_TAIL ==="
    tail -n 220 "$log" || true
  } | sed -e 's/\r$//'
}

# 給 agent 的 prompt：要求「先搜檔案定位 + 最小修改 + 再 build」
build_agent_prompt() {
  local round="$1"
  local errtxt="$2"

  cat <<PROMPT
你是 Seedsomething 專案的 iOS/SwiftUI 工程代理（Xcode 16.3 + iOS 18.4 Simulator + Firebase SPM）。

【當前目標】
自動修復 build 錯誤（第 ${round}/${MAX_ROUNDS} 輪），要求：最小修改、可編譯、能通過 build。

【硬性規則（必須遵守）】
1) 先用 shell 在 repo 內搜尋定位相關檔案/類型（不得猜檔名/路徑）。
2) 修改必須最小化：能加 1 行就不加 10 行。
3) 修完後必須跑：
   - $ROOT/scripts/ai_verify.sh
   - 若仍因 simulator destination 問題，改跑：$ROOT/scripts/ai_build.sh
4) 最終輸出必須包含：
   - 修改檔案清單
   - 每檔改動摘要
   - 驗證結果（OK/FAIL）
   - git diff 重點區塊（只貼關鍵）

【錯誤摘要（你必須以此為準修復）】
$errtxt
PROMPT
}

auto_commit() {
  local msg="$1"
  git add .
  git commit -m "$msg" >/dev/null 2>&1 || true
}

for round in $(seq 1 "$MAX_ROUNDS"); do
  echo
  echo "=============================="
  echo "== AutoFix Round $round/$MAX_ROUNDS =="
  echo "=============================="

  LOG="$LOG_DIR/autofix_round_${round}.log"

  if run_build_once "$LOG"; then
    echo "✅ BUILD OK (round $round)"
    # 有變更才 commit
    if ! git diff --quiet || ! git diff --cached --quiet; then
      auto_commit "$TASK_PREFIX: build ok (round $round)"
    fi
    echo "== Done =="
    git status || true
    exit 0
  fi

  echo "❌ BUILD FAIL (round $round) — extracting errors..."
  ERR_TXT="$(extract_errors "$LOG")"

  PROMPT="$(build_agent_prompt "$round" "$ERR_TXT")"

  echo "== Run OpenClaw Agent ==" 
  # 這裡必須指定 agent，避免 gateway session 問題
  openclaw agent --agent main -m "$PROMPT"

  # agent 改完先 auto commit（每輪小步）
  if ! git diff --quiet; then
    auto_commit "$TASK_PREFIX: apply fix (round $round)"
  fi
done

echo "❌ AutoFix exhausted after $MAX_ROUNDS rounds."
echo "你可以把最後一輪 log 丟給我：$LOG_DIR/autofix_round_${MAX_ROUNDS}.log"
exit 1
