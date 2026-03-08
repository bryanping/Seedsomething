//
//  Grass.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation
import SwiftUI

/// 草的成长阶段（状态机核心）
enum GrassStage: String, Codable, CaseIterable {
    case seedling = "seedling"   // 幼苗
    case growing = "growing"     // 成长中
    case mature = "mature"       // 成熟
    case bloom = "bloom"         // 开花
    case dormant = "dormant"     // 休眠（如久未浇水或冬季）

    var displayName: String {
        switch self {
        case .seedling: return "幼苗"
        case .growing: return "成长中"
        case .mature: return "成熟"
        case .bloom: return "开花"
        case .dormant: return "休眠"
        }
    }
}

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

    /// 成长阶段（可计算、可存；用于季节皮肤与状态展示）
    var stage: GrassStage
    /// 健康度 0–100，影响外观与状态文案
    var health: Int

    // 语义别名（与 lastCheckinAt / consecutiveDays / totalCheckinCount 一致）
    var lastWateredAt: Date? {
        get { lastCheckinAt }
        set { lastCheckinAt = newValue }
    }
    /// 最后浇水日期（与 lastWateredAt 同义，满足状态机命名）
    var lastWateredDate: Date? {
        get { lastCheckinAt }
        set { lastCheckinAt = newValue }
    }
    var streak: Int { consecutiveDays }
    var totalWaterCount: Int { totalCheckinCount }

    /// 是否缺水（今天尚未浇水）
    var isThirsty: Bool { !hasCheckedInToday }

    enum CodingKeys: String, CodingKey {
        case id, userId, level, exp, lastCheckinAt, totalCheckinCount, createdAt, consecutiveDays
        case mood, hasFlower, hasDew, decorationPoints, plantSpecies, mutationLevel, mutationName
        case stage, health
    }

    // 每級所需經驗值（成長速度慢）
    static let expPerLevel = 100

    init(
        id: String = UUID().uuidString, userId: String, level: Int = 1, exp: Int = 0,
        lastCheckinAt: Date? = nil, totalCheckinCount: Int = 0, createdAt: Date = Date(),
        consecutiveDays: Int = 0, mood: GrassMood = GrassMood.sunny, hasFlower: Bool = false,
        hasDew: Bool = false, decorationPoints: Int = 0, plantSpecies: PlantSpecies? = nil,
        mutationLevel: Int = 0, mutationName: String? = nil,
        stage: GrassStage = .seedling, health: Int = 100
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
        self.stage = stage
        self.health = min(100, max(0, health))
        // 如果没有指定植物种类，根据用户ID生成确定性随机植物
        self.plantSpecies = plantSpecies ?? PlantRandomizer.deterministicPlant(for: userId)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        userId = try c.decode(String.self, forKey: .userId)
        level = try c.decode(Int.self, forKey: .level)
        exp = try c.decode(Int.self, forKey: .exp)
        lastCheckinAt = try c.decodeIfPresent(Date.self, forKey: .lastCheckinAt)
        totalCheckinCount = try c.decode(Int.self, forKey: .totalCheckinCount)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        consecutiveDays = try c.decode(Int.self, forKey: .consecutiveDays)
        mood = try c.decode(GrassMood.self, forKey: .mood)
        hasFlower = try c.decode(Bool.self, forKey: .hasFlower)
        hasDew = try c.decode(Bool.self, forKey: .hasDew)
        decorationPoints = try c.decode(Int.self, forKey: .decorationPoints)
        plantSpecies = try c.decodeIfPresent(PlantSpecies.self, forKey: .plantSpecies)
        mutationLevel = try c.decode(Int.self, forKey: .mutationLevel)
        mutationName = try c.decodeIfPresent(String.self, forKey: .mutationName)
        stage = (try? c.decode(GrassStage.self, forKey: .stage)) ?? .seedling
        health = (try? c.decode(Int.self, forKey: .health)) ?? 100
    }

    // 增加經驗值（微小成長）
    mutating func addExp(_ amount: Int) {
        exp += amount
        while exp >= Grass.expPerLevel {
            exp -= Grass.expPerLevel
            level += 1
        }
        updateStage()
    }

    /// 根据等级与季节刷新 stage
    mutating func refreshStageFromLevel() {
        if stage == .dormant { return } // 休眠由季节/健康度单独处理
        switch level {
        case 1...2: stage = .seedling
        case 3...5: stage = .growing
        case 6...9: stage = .mature
        default: stage = .bloom
        }
    }

    // MARK: - 成长状态机：浇水与阶段

    /// 浇水一次：总次数+1、更新最后浇水日、重算连续天数、并刷新阶段
    mutating func water() {
        guard !hasCheckedInToday else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let oldLast = lastCheckinAt
        totalCheckinCount += 1
        lastCheckinAt = Date()

        if let last = oldLast.map({ calendar.startOfDay(for: $0) }) {
            if calendar.isDate(last, inSameDayAs: yesterday) {
                consecutiveDays += 1
            } else if !calendar.isDate(last, inSameDayAs: today) {
                consecutiveDays = 1
            }
        } else {
            consecutiveDays = 1
        }

        updateStage()
    }

    /// 按连续天数与总浇水次数阈值自动切换 stage（达阈值自动切阶段）
    mutating func updateStage() {
        if stage == .dormant { return }
        if streak >= 10 {
            stage = .bloom
        } else if streak >= 6 {
            stage = .mature
        } else if streak >= 3 {
            stage = .growing
        } else {
            stage = .seedling
        }
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

        // 冬季可进入休眠（仅影响展示，不强制改 stage）
        if season == .winter && consecutiveDays < 7 {
            stage = .dormant
        } else {
            updateStage()
        }

        // 更新 mood
        if !hasCheckedInToday {
            mood = GrassMood.needsWater
            if health > 0 { health = max(0, health - 5) } // 未浇水日略降健康
        } else {
            mood = GrassMood.sunny
            health = min(100, health + 2) // 浇水日略恢复
        }
        if hasFlower {
            mood = GrassMood.flowering
        }
    }

    // 计算草的高度（随成长值变化）
    /// 当前等级内经验进度 0...1（用于成长条展示）
    var expPercentage: Double {
        let p = Double(exp) / Double(Grass.expPerLevel)
        return min(1, max(0, p))
    }
    var height: CGFloat {
        let baseHeight: CGFloat = 60
        let growthPerLevel: CGFloat = 8
        return baseHeight + CGFloat(level) * growthPerLevel
    }
}
