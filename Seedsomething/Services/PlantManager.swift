//
//  PlantManager.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation
import CoreLocation
import SwiftUI

class PlantManager: NSObject, ObservableObject {
    static let shared = PlantManager()
    
    @Published var grass: Grass?
    @Published var plantRecords: [PlantRecord] = []
    @Published var stores: [Store] = []
    
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    
    private init() {
        setupLocationManager()
        loadData()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // 打卡（種草）
    func checkIn() async throws {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw PlantError.notAuthenticated
        }
        
        guard let location = currentLocation else {
            throw PlantError.locationNotAvailable
        }
        
        // 檢查今天是否已打卡
        if let grass = grass, grass.hasCheckedInToday {
            throw PlantError.alreadyCheckedInToday
        }
        
        // 創建打卡記錄
        let record = PlantRecord(
            userId: userId,
            type: .personalCheckin,
            coordinate: Coordinate(location: location)
        )
        
        plantRecords.append(record)
        
        // 更新草資料
        if var currentGrass = grass {
            currentGrass.addExp(10)
            currentGrass.lastCheckinAt = Date()
            currentGrass.totalCheckinCount += 1
            self.grass = currentGrass
        } else {
            // 創建新的草
            var newGrass = Grass(userId: userId)
            newGrass.addExp(10)
            newGrass.lastCheckinAt = Date()
            newGrass.totalCheckinCount = 1
            self.grass = newGrass
        }
        
        saveData()
    }
    
    // 掃碼種草
    func scanAndPlant(storeId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw PlantError.notAuthenticated
        }
        
        guard let store = stores.first(where: { $0.id == storeId }) else {
            throw PlantError.storeNotFound
        }
        
        guard let location = currentLocation else {
            throw PlantError.locationNotAvailable
        }
        
        // 創建店家掃碼記錄
        let record = PlantRecord(
            userId: userId,
            type: .storeScan,
            coordinate: Coordinate(location: location),
            storeId: storeId
        )
        
        plantRecords.append(record)
        
        // 更新草資料
        if var currentGrass = grass {
            currentGrass.addExp(15) // 店家掃碼經驗值更高
            self.grass = currentGrass
        } else {
            var newGrass = Grass(userId: userId)
            newGrass.addExp(15)
            self.grass = newGrass
        }
        
        // 更新店家種草數
        if let index = stores.firstIndex(where: { $0.id == storeId }) {
            stores[index].totalPlantCount += 1
        }
        
        saveData()
    }
    
    // 創建店家花園
    func createStore(name: String, coordinate: Coordinate) async throws -> Store {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw PlantError.notAuthenticated
        }
        
        let store = Store(
            ownerUserId: userId,
            name: name,
            coordinate: coordinate
        )
        
        stores.append(store)
        saveData()
        
        return store
    }
    
    // 根據 QR Token 查找店家
    func findStoreByQRToken(_ token: String) -> Store? {
        return stores.first { $0.qrCodeToken == token }
    }
    
    private func saveData() {
        // TODO: 實際應該儲存到後端或本地資料庫
        if let grass = grass, let encoded = try? JSONEncoder().encode(grass) {
            UserDefaults.standard.set(encoded, forKey: "grass")
        }
        if let encoded = try? JSONEncoder().encode(plantRecords) {
            UserDefaults.standard.set(encoded, forKey: "plantRecords")
        }
        if let encoded = try? JSONEncoder().encode(stores) {
            UserDefaults.standard.set(encoded, forKey: "stores")
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "grass"),
           let decoded = try? JSONDecoder().decode(Grass.self, from: data) {
            grass = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "plantRecords"),
           let decoded = try? JSONDecoder().decode([PlantRecord].self, from: data) {
            plantRecords = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "stores"),
           let decoded = try? JSONDecoder().decode([Store].self, from: data) {
            stores = decoded
        }
    }
}

extension PlantManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位錯誤: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
}

enum PlantError: LocalizedError {
    case notAuthenticated
    case locationNotAvailable
    case alreadyCheckedInToday
    case storeNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "請先登入"
        case .locationNotAvailable:
            return "無法取得位置資訊"
        case .alreadyCheckedInToday:
            return "今日已打卡"
        case .storeNotFound:
            return "找不到店家"
        }
    }
}

