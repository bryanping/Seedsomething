# Seedsomething - Project Context

## Repo
- iOS 專案：Seedsomething.xcodeproj
- 主程式碼：Seedsomething/
- docs：
  - FIREBASE_SECURITY_RULES.md
  - FIREBASE_INDEX_SETUP.md
  - GAODE_MAP_SETUP.md
  - PLANT_PROMPTS.md
  - README.md

## 產品方向（核心玩法）
- 種植 / 成長 / 稀有機率
- 玩法觸發（成長中事件）
- 季節背景（Home 背景變化）
- 每日任務（任務 UI + 完成回饋）
- Firebase 同步（使用者資料、植物、任務、成就）

## 高風險區（先保守）
- Firebase rules / index：先照既有 md，功能先跑起來再收緊
- 登入與使用者資料：先匿名/簡單資料模型，再擴充
- 付費與訂閱：本期不做，只保留擴展點（protocol/feature flag）
