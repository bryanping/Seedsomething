# 高德地图集成说明

## 概述

对于中国大陆用户，应用使用高德地图 SDK 提供更好的地图服务。其他地区使用 Apple MapKit。

## 集成步骤

### 1. 添加高德地图 SDK

#### 使用 CocoaPods（推荐）

1. 在项目根目录创建或编辑 `Podfile`：

```ruby
platform :ios, '13.0'
use_frameworks!

target 'Seedsomething' do
  # 高德地图 SDK
  pod 'AMap3DMap'        # 3D地图SDK
  pod 'AMapSearch'       # 搜索SDK
  pod 'AMapLocation'     # 定位SDK
end
```

2. 运行安装命令：
```bash
pod install
```

3. 使用 `.xcworkspace` 文件打开项目（不是 `.xcodeproj`）

#### 使用 Swift Package Manager

高德地图 SDK 目前不支持 SPM，请使用 CocoaPods 或手动集成。

### 2. 获取高德地图 API Key

1. 访问 [高德开放平台](https://lbs.amap.com/)
2. 注册/登录账号
3. 创建应用，获取 API Key
4. 在 `Info.plist` 中添加：

```xml
<key>AMapAPIKey</key>
<string>7862dff5b19c0f7a7e69bc0949d567bc</string>
```

**注意**：API Key 已配置在 `Info.plist` 和 `MapService.swift` 中。

### 3. 配置 Info.plist

添加定位权限说明：

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>我們需要您的位置來記錄您的種草足跡</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>我們需要您的位置來記錄您的種草足跡</string>
```

### 4. 代码集成

#### 创建高德地图视图包装器

```swift
// GaodeMapView.swift
import SwiftUI
import AMapFoundationKit
import MAMapKit

struct GaodeMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [PlantRecord]
    var onAnnotationTap: (PlantRecord) -> Void
    
    func makeUIView(context: Context) -> MAMapView {
        let mapView = MAMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userLocation.title = "我的位置"
        return mapView
    }
    
    func updateUIView(_ mapView: MAMapView, context: Context) {
        // 更新地图中心
        let coordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        mapView.setCenter(coordinate, animated: true)
        
        // 更新标注
        mapView.removeAnnotations(mapView.annotations)
        // 添加标注...
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MAMapViewDelegate {
        var parent: GaodeMapView
        
        init(_ parent: GaodeMapView) {
            self.parent = parent
        }
        
        // 实现 MAMapViewDelegate 方法...
    }
}
```

#### 在 MapView 中使用

```swift
// 根据地区选择地图
if MapService.shared.isInMainlandChina {
    GaodeMapView(region: $region, annotations: plantManager.plantRecords) { record in
        selectedRecord = record
    }
} else {
    Map { /* Apple MapKit */ }
}
```

### 5. 初始化高德地图

在 `SeedsomethingApp.swift` 中：

```swift
import AMapFoundationKit

@main
struct SeedsomethingApp: App {
    init() {
        // 初始化 Firebase
        FirebaseApp.configure()
        
        // 初始化高德地图（如果在中国）
        // MapService 会自动处理初始化
        _ = MapService.shared
    }
    
    // ...
}
```

**注意**：API Key (`7862dff5b19c0f7a7e69bc0949d567bc`) 已配置在 `MapService.swift` 中。

## 注意事项

1. **API Key 安全**：不要将 API Key 提交到公开仓库，使用环境变量或配置文件
2. **地区判断**：当前使用简化的地区判断，实际应该根据 IP 或更准确的地理位置
3. **地图切换**：用户在不同地区使用时，可能需要重启应用才能切换地图服务
4. **性能**：高德地图 SDK 会增加应用体积，考虑使用动态框架

## 功能对比

| 功能 | Apple MapKit | 高德地图 |
|------|-------------|---------|
| 中国大陆地图数据 | 有限 | 完整 |
| 定位精度 | 一般 | 更精确 |
| 搜索功能 | 基础 | 丰富 |
| 离线地图 | 不支持 | 支持 |
| 集成难度 | 简单 | 中等 |

## 参考文档

- [高德地图 iOS SDK 文档](https://lbs.amap.com/api/ios-sdk/summary)
- [高德开放平台](https://lbs.amap.com/)

