# Seedsomething 上架銷售待辦

以 **App Store 上架銷售** 為目標，整理目前專案缺失的功能與頁面。

---

## 一、法律與合規（審核必要）

- [ ] **隱私政策頁**
  - 撰寫並 host 隱私政策（說明資料收集、Firebase、位置、日記與好友資料等）
  - 提供可公開訪問的 URL（例如官網或靜態頁）

- [ ] **用戶協議 / 服務條款頁**
  - 撰寫服務條款並提供 URL

- [ ] **設定頁串接**
  - 在 `SettingsView` 新增「隱私政策」「服務條款」項目，點擊以 `SafariServices` 或 `Link` 開啟上述 URL
  - 登入畫面或註冊流程中可視需求加上「同意服務條款與隱私政策」勾選（依審核實務調整）

---

## 二、帳號與數據（App Store 要求）

- [ ] **刪除帳號**暫時不做
  - 在設定或「我的」中提供「刪除帳號」入口
  - 流程：確認 → 呼叫 Firebase Auth 刪除帳號並清理 Firestore 中該用戶資料（或標記刪除）
  - Apple 審核會要求 App 內可註銷/刪除帳號

- [ ] **數據導出（建議）**暫時不做
  - 提供「導出我的數據」：可下載日記、種草記錄等（JSON/檔案或郵件），提升透明度與合規

---

## 三、權限與 Info.plist

- [ ] **相機權限說明**
  - 若使用相機掃描店家/好友 QR，在 `Info.plist` 新增 `NSCameraUsageDescription`，說明為何需要相機（例如：「用於掃描店家與好友的種草 QR Code」）

- [ ] **現有權限**
  - 已具備 `NSLocationWhenInUseUsageDescription`、`NSLocationAlwaysAndWhenInUseUsageDescription`，上架前再確認文案與實際使用一致

---

## 四、缺失頁面與導航

- [ ] **任務頁入口**
  - `TasksView` 已存在，但 App 內無入口（僅在 Home 顯示每日任務橫向卡片）
  - 做法二選一或並行：
    - 在首頁「每日任務」區塊加「查看全部」按鈕，`NavigationLink` 或 `.sheet` 進入 `TasksView`
    - 或將「任務」加入 TabBar（`ContentView` 的 `TabView`）作為獨立 Tab

- [ ] **植物圖鑑入口**
  - `PlantEncyclopediaView` 已存在，確認是否有從首頁或「我的」進入的入口；若無，需新增（例如首頁或 Profile 的「植物圖鑑」按鈕）

- [ ] **關於 / 版本資訊**
  - 設定頁已有「當前版本 v1.0.0 (Alpha)」
  - 上架前：改為正式版號（例如 1.0.0），並可新增「關於我們」頁（簡短介紹、官網/社群連結）

---

## 五、首次使用體驗（建議）

- [ ] **Onboarding 引導**
  - 首次安裝或首次登入後顯示 2–4 頁簡短引導：介紹「種草」、地圖打卡、日記、好友、店家掃碼等
  - 用 `UserDefaults` 或 Firebase 記錄是否已看過，避免重複顯示

---

## 六、功能補全與穩定性

- [ ] **店家 QR 掃描**
  - `QRScannerView` 目前為 `simulateScan()` 模擬，需改為使用 `AVCaptureSession` 等真實相機掃描 QR，並在無權限時提示前往設定開啟相機

- [ ] **網路與錯誤處理**
  - 關鍵操作（登入、種草、載入地圖、日記同步）的網路錯誤、Firestore 錯誤要有明確提示（例如 Alert 或 inline 訊息）
  - 可選：無網路時顯示簡短提示或離線模式說明

- [ ] **啟動圖**
  - `Info.plist` 中 `UILaunchScreen` 目前為空，可設定 Launch Storyboard 或靜態圖，避免白屏

---

## 七、上架前檢查清單

- [ ] 版本號：`CFBundleShortVersionString` / `CFBundleVersion` 與設定頁顯示一致，且為正式版（非 Alpha）
- [ ] 隱私政策與服務條款 URL 在 App 內可點開，且內容與實際行為一致
- [ ] 刪除帳號流程可實際執行並通過測試
- [ ] 所有用到的權限（定位、相機等）皆有對應 Usage Description
- [ ] App Store 素材：截圖、描述、關鍵字、定價（若為付費或訂閱）
- [ ] 若使用 Sign in with Apple，須在 App Store Connect 啟用並通過審核設定

---

## 現有結構速覽（供對照）

| 項目           | 狀態 |
|----------------|------|
| 登入（Apple / Email） | ✅ |
| 首頁（我的草、澆水、日記、每日任務預覽、好友預覽） | ✅ |
| 地圖（打卡、足跡）   | ✅ |
| 我的（Profile、成就、好友、店家花園、設定、登出） | ✅ |
| 日記             | ✅（從首頁 sheet 進入） |
| 任務完整頁（TasksView） | ⚠️ 無入口 |
| 植物圖鑑（PlantEncyclopediaView） | ⚠️ 需確認入口 |
| 設定（季節、版本）   | ✅，缺隱私/條款連結 |
| 隱私政策 / 服務條款  | ❌ |
| 刪除帳號          | ❌ |
| 店家 QR 真實掃描   | ❌（目前模擬） |
| Onboarding      | ❌ |
| Launch Screen   | ❌ 未設定 |

以上依優先級與審核必要項排序，可依時程先完成「一、二、三、四、七」再補五與六。
