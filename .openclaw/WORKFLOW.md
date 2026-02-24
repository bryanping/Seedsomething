# Workflow - Seedsomething AI Dev Loop

## 每輪固定流程
1) 掃描
- git status
- rg 搜關鍵字定位入口檔（Home/Root/App/Scene）
- 列出可能需要改的檔案清單

2) 方案
- 用 3~6 步寫出最短實作路徑
- 明確：新增哪些 type / view / model / firestore path（若有）

3) 實作
- 小步提交，避免大改動
- 優先：UI 可見 + 假資料可跑
- 再接：Firebase/真資料

4) 驗證
- scripts/ai_verify.sh（必要）
- 若 verify 指向特定 simulator：確保 destination 存在（iPhone 16）

5) 回報
- 修改檔案清單
- 每檔改動摘要
- 驗證結果（OK/FAIL + 錯誤關鍵行）
- git diff 重點區塊

## Build 目的地
- iOS Simulator：iPhone 16（iOS 18.4）
