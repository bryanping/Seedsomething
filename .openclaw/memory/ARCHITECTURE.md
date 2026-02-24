# Architecture (Seedsomething)

## Layering
- SwiftUI Views
- ViewModels（若已有則沿用，沒有就先用輕量 state + service）
- Services（Firebase / RNG / Growth Engine）
- Models（Plant / Task / User）

## Firebase（暫定方向）
- users/{uid}
- users/{uid}/plants/{plantId}
- users/{uid}/dailyTasks/{dateId}

（未確認前先不大量重構）
