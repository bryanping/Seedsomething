//
//  Grass.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation
import SwiftUI

struct Grass: Identifiable, Codable {
    let id: String
    let userId: String
    var level: Int
    var exp: Int
    var lastCheckinAt: Date?
    var totalCheckinCount: Int
    var createdAt: Date
    var consecutiveDays: Int
    var mood: GrassMood
    var hasFlower: Bool  // 是否有小花
    var hasDew: Bool  // 是否有露珠
    var decorationPoints: Int  // 装饰点数
    var plantSpecies: PlantSpecies?  // 植物种类（可选，用于随机植物系统）
    var mutationLevel: Int  // 0 = 普通, 1-4 = 稀有变异等级
    var mutationName: String?  // 变异后的名称（如：五叶草）

    // 每級所需經驗值（成長速度慢）
    static let expPerLevel = 100

    init(
        id: String = UUID().uuidString, userId: String, level: Int = 1, exp: Int = 0,
        lastCheckinAt: Date? = nil, totalCheckinCount: Int = 0, createdAt: Date = Date(),
        consecutiveDays: Int = 0, mood: GrassMood = GrassMood.sunny, hasFlower: Bool = false,
        hasDew: Bool = false, decorationPoints: Int = 0, plantSpecies: PlantSpecies? = nil,
        mutationLevel: Int = 0, mutationName: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.level = level
        self.exp = exp
        self.lastCheckinAt = lastCheckinAt
        self.totalCheckinCount = totalCheckinCount
        self.createdAt = createdAt
        self.consecutiveDays = consecutiveDays
        self.mood = mood
        self.hasFlower = hasFlower
        self.hasDew = hasDew
        self.decorationPoints = decorationPoints
        self.mutationLevel = mutationLevel
        self.mutationName = mutationName
        // 如果没有指定植物种类，根据用户ID生成确定性随机植物
        self.plantSpecies = plantSpecies ?? PlantRandomizer.deterministicPlant(for: userId)
    }

    // 增加經驗值（微小成長）
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

    // 草龄（天数）
    var ageInDays: Int {
        let days = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        return max(1, days)
    }

    // 根据季节更新状态
    mutating func updateForSeason(_ season: Season) {
        // 季节限定花
        if season.hasFlower && consecutiveDays >= 7 {
            hasFlower = true
        } else {
            hasFlower = false
        }

        // 30天露珠
        if consecutiveDays >= 30 {
            hasDew = true
        }

        // 更新 mood
        if !hasCheckedInToday {
            mood = GrassMood.needsWater
        } else if hasFlower {
            mood = GrassMood.flowering
        } else {
            mood = GrassMood.sunny
        }
    }

    // 计算草的高度（随成长值变化）
    var height: CGFloat {
        let baseHeight: CGFloat = 60
        let growthPerLevel: CGFloat = 8
        return baseHeight + CGFloat(level) * growthPerLevel
    }
}
