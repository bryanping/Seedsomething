# SeedSomething - 種點什麼

一個以「草」為人格化主體、以「打卡＝種草」為玩法核心的輕社交 + 足跡紀錄 App。

## 專案簡述

使用者就是一顆草，每次打卡、到店掃碼，都是「在地圖上種下一株草」。店家可以建立自己的「小花園」，使用者可在現場掃碼種草。

## 技術棧

- **語言**: Swift 5.0+
- **框架**: SwiftUI
- **最低支援**: iOS 17.0+
- **地圖**: MapKit
- **認證**: Apple Sign In, Google Sign In (待實作)

## 專案結構

```
SeedSomething/
├── Models/              # 資料模型
│   ├── User.swift
│   ├── Grass.swift
│   ├── PlantRecord.swift
│   └── Store.swift
├── Services/            # 服務層
│   ├── AuthManager.swift
│   └── PlantManager.swift
├── Views/               # 視圖
│   ├── HomeView.swift
│   ├── MapView.swift
│   ├── ProfileView.swift
│   ├── QRScannerView.swift
│   └── StoreGardenView.swift
├── Utils/               # 工具類
│   └── BrandColors.swift
└── ContentView.swift    # 主視圖
```

## 功能清單

### 使用者功能
- ✅ 註冊 / 登入（Apple Sign In）
- ✅ 主頁：我的草（等級、經驗、今日打卡）
- ✅ 打卡（GPS）＝種下一株草
- ✅ 地圖瀏覽自己的種草足跡
- ✅ 掃描店家 QR Code → 在店家花園種草
- ✅ 查看個人種草紀錄

### 店家功能
- ✅ 建立「店家花園」
- ✅ 產生店家專屬 QR Code
- ✅ 查看店家被種草的總次數

## 品牌系統

### 顏色
- 主綠（嫩芽）: `#A8E6A3`
- 深綠（葉脈）: `#6A9E58`
- 深灰（手繪線條）: `#4A4A4A`
- 奶油白（手帳紙質）: `#FAF7EF`
- 灰綠（次要背景）: `#BFD6BF`

### 字體
- 標題：PingFang TC（圓角無襯線）
- 正文：系統字體

## 開發注意事項

1. **定位權限**: 需要在 Info.plist 中設定 `NSLocationWhenInUseUsageDescription`
2. **相機權限**: 需要在 Info.plist 中設定 `NSCameraUsageDescription`
3. **Apple Sign In**: 需要在 Capabilities 中啟用 Sign in with Apple
4. **資料儲存**: 目前使用 UserDefaults，實際部署應改為後端 API

## 待完成項目

- [ ] 實作完整的 Google Sign In
- [ ] 實作真實的相機掃描功能（AVFoundation）
- [ ] 連接後端 API（Firebase/Supabase）
- [ ] 實作連續打卡天數計算邏輯
- [ ] 優化地圖標記顯示
- [ ] 添加手繪風格插圖資源
- [ ] 實作設定頁面

## 執行方式

1. 使用 Xcode 開啟 `SeedSomething.xcodeproj`
2. 選擇目標裝置或模擬器
3. 按 Cmd+R 執行

## 授權

本專案為內部專案。

