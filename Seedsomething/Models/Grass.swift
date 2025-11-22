//
//  Grass.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation

struct Grass: Identifiable, Codable {
    let id: String
    let userId: String
    var level: Int
    var exp: Int
    var lastCheckinAt: Date?
    var totalCheckinCount: Int
    
    // 每級所需經驗值
    static let expPerLevel = 100
    
    init(id: String = UUID().uuidString, userId: String, level: Int = 1, exp: Int = 0, lastCheckinAt: Date? = nil, totalCheckinCount: Int = 0) {
        self.id = id
        self.userId = userId
        self.level = level
        self.exp = exp
        self.lastCheckinAt = lastCheckinAt
        self.totalCheckinCount = totalCheckinCount
    }
    
    // 增加經驗值，如果滿級則升級
    mutating func addExp(_ amount: Int) {
        exp += amount
        while exp >= Grass.expPerLevel {
            exp -= Grass.expPerLevel
            level += 1
        }
    }
    
    // 經驗值百分比
    var expPercentage: Double {
        return Double(exp) / Double(Grass.expPerLevel)
    }
    
    // 檢查今天是否已打卡
    var hasCheckedInToday: Bool {
        guard let lastCheckin = lastCheckinAt else { return false }
        return Calendar.current.isDateInToday(lastCheckin)
    }
    
    // 計算連續打卡天數（簡化版，實際需要更複雜的邏輯）
    var consecutiveDays: Int {
        // TODO: 實現連續打卡天數計算
        return 1
    }
}

