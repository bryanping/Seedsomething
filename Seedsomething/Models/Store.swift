//
//  Store.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation

struct Store: Identifiable, Codable {
    let id: String
    let ownerUserId: String
    var name: String
    let coordinate: Coordinate
    let qrCodeToken: String
    var totalPlantCount: Int
    
    init(id: String = UUID().uuidString, ownerUserId: String, name: String, coordinate: Coordinate, qrCodeToken: String = UUID().uuidString, totalPlantCount: Int = 0) {
        self.id = id
        self.ownerUserId = ownerUserId
        self.name = name
        self.coordinate = coordinate
        self.qrCodeToken = qrCodeToken
        self.totalPlantCount = totalPlantCount
    }
}

