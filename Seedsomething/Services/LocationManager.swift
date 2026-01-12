//
//  LocationManager.swift
//  Seedsomething
//
//  GPS / 定位管理器  // 修改內容
//

import Foundation
import CoreLocation
import SwiftUI

/// 統一管理定位權限與座標 // 修改內容
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()          // 單例 // 修改內容
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?       // 最近一次位置 // 修改內容
    @Published var errorMessage: String?           // 錯誤訊息 // 修改內容
    
    private let manager = CLLocationManager()
    
    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest  // 可視需求調整 // 修改內容
    }
    
    /// 請求「使用期間」定位權限 // 修改內容
    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// 開始更新位置（前臺） // 修改內容
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    /// 停止更新位置 // 修改內容
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            errorMessage = nil
        case .denied, .restricted:
            errorMessage = "定位權限已關閉，請到系統設定中開啟。"
        case .notDetermined:
            errorMessage = nil
        @unknown default:
            errorMessage = "未知的定位權限狀態。"
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        errorMessage = "定位失敗：\(error.localizedDescription)"
    }
}
