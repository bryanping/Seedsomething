//
//  PlantRecord.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation
import CoreLocation

enum PlantRecordType: String, Codable {
    case personalCheckin = "personal_checkin"
    case storeScan = "store_scan"
}

struct PlantRecord: Identifiable, Codable {
    let id: String
    let userId: String
    let type: PlantRecordType
    let coordinate: Coordinate
    let storeId: String?
    let createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, type: PlantRecordType, coordinate: Coordinate, storeId: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.type = type
        self.coordinate = coordinate
        self.storeId = storeId
        self.createdAt = createdAt
    }
}

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(location: CLLocationCoordinate2D) {
        self.latitude = location.latitude
        self.longitude = location.longitude
    }
    
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

