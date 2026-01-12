//
//  MapService.swift
//  Seedsomething
//
//  地图服务 - 处理不同地区的地图选择（中国使用高德地图）
//

import Foundation
import CoreLocation

class MapService {
    static let shared = MapService()
    
    /// 高德地图 API Key
    let gaodeAPIKey = "7862dff5b19c0f7a7e69bc0949d567bc"
    
    /// 判断是否在中国大陆
    /// 注意：暂时禁用自动判断，避免在没有高德地图 SDK 时崩溃
    var isInMainlandChina: Bool {
        // 暂时返回 false，避免在没有高德地图 SDK 时尝试初始化导致崩溃
        // 集成高德地图 SDK 后，可以取消下面的注释
        return false
        
        /*
        // 方法1：根据系统区域设置判断
        if let regionCode = Locale.current.region?.identifier {
            return regionCode == "CN"
        }
        
        // 方法2：根据语言设置判断（简化）
        let preferredLanguage = Locale.preferredLanguages.first ?? ""
        return preferredLanguage.contains("zh-Hans") || preferredLanguage.contains("zh-CN")
        */
    }
    
    /// 获取地图类型
    var mapType: MapProvider {
        return isInMainlandChina ? .gaode : .apple
    }
    
    /// 地图提供商枚举
    enum MapProvider {
        case apple      // Apple MapKit
        case gaode      // 高德地图
    }
    
    /// 初始化高德地图（如果在中国）
    /// 注意：暂时禁用，避免在没有 SDK 时崩溃
    func configureGaodeMapIfNeeded() {
        // 暂时禁用高德地图初始化，避免在没有 SDK 时崩溃
        // 集成高德地图 SDK 后，取消下面的注释
        /*
        if isInMainlandChina {
            #if canImport(AMapFoundationKit)
            AMapServices.shared()?.apiKey = gaodeAPIKey
            #endif
        }
        */
    }
    
    private init() {
        // 暂时不自动初始化，避免崩溃
        // configureGaodeMapIfNeeded()
    }
}

