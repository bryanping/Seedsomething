# Decisions Log (Seedsomething)

- 2026-02-24：自動 build destination 固定 iPhone 16（iOS 18.4），避免 iPhone 15 不存在造成 verify 失敗。
- 2026-02-24：agent 每輪必跑 scripts/ai_verify.sh，失敗再跑 scripts/ai_build.sh 作為 fallback。
