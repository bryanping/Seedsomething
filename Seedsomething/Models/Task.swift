//
//  Task.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation

enum TaskType: String, Codable, CaseIterable {
    case water = "water"  // 浇水（每日一次）
    case exercise = "exercise"  // 运动
    case reading = "reading"  // 阅读
    case earlySleep = "early_sleep"  // 早睡
    case meditation = "meditation"  // 冥想
    case custom = "custom"  // 自定义

    var displayName: String {
        switch self {
        case .water: return "浇水"
        case .exercise: return "运动"
        case .reading: return "阅读"
        case .earlySleep: return "早睡"
        case .meditation: return "冥想"
        case .custom: return "自定义"
        }
    }

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .exercise: return "figure.run"
        case .reading: return "book.fill"
        case .earlySleep: return "moon.fill"
        case .meditation: return "leaf.fill"
        case .custom: return "star.fill"
        }
    }

    var expReward: Int {
        switch self {
        case .water: return 1  // 基础，微小成长
        case .exercise, .reading, .earlySleep, .meditation: return 1
        case .custom: return 1
        }
    }
}

struct UserTask: Identifiable, Codable {
    let id: String
    let userId: String
    let type: TaskType
    var name: String
    var isEnabled: Bool
    var completedDates: [Date]  // 完成日期列表

    init(
        id: String = UUID().uuidString, userId: String, type: TaskType, name: String? = nil,
        isEnabled: Bool = true, completedDates: [Date] = []
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.name = name ?? type.displayName
        self.isEnabled = isEnabled
        self.completedDates = completedDates
    }

    // 今天是否已完成
    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return completedDates.contains { date in
            Calendar.current.isDate(date, inSameDayAs: today)
        }
    }

    // 完成任务
    mutating func complete() {
        let today = Date()
        if !isCompletedToday {
            completedDates.append(today)
        }
    }
}

enum AchievementType: String, Codable {
    case consecutive7Days = "consecutive_7_days"  // 连浇7天 → 小花开启
    case consecutive30Days = "consecutive_30_days"  // 30天 → 草带白露
    case summerGrowth = "summer_growth"  // 夏季成长值达标
    case firstFriend = "first_friend"  // 有第一个好友
    case friendLike = "friend_like"  // 和朋友互相点赞
    case storePlant = "store_plant"  // 在某家店种下草
    case totalCheckins = "total_checkins"  // 总打卡次数

    var displayName: String {
        switch self {
        case .consecutive7Days: return "小花开启"
        case .consecutive30Days: return "白露降临"
        case .summerGrowth: return "盛夏限定花"
        case .firstFriend: return "第一个朋友"
        case .friendLike: return "点赞互动"
        case .storePlant: return "店家种草"
        case .totalCheckins: return "持之以恒"
        }
    }

    var description: String {
        switch self {
        case .consecutive7Days: return "连续浇水7天"
        case .consecutive30Days: return "连续浇水30天"
        case .summerGrowth: return "夏季成长值达标"
        case .firstFriend: return "添加第一个好友"
        case .friendLike: return "和朋友互相点赞"
        case .storePlant: return "在店家种下草"
        case .totalCheckins: return "累计打卡次数达标"
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let userId: String
    let type: AchievementType
    var isUnlocked: Bool
    var unlockedAt: Date?
    var level: Int  // 成就等级（LV）
    var progress: Int  // 当前进度
    var target: Int  // 目标值

    init(
        id: String = UUID().uuidString, userId: String, type: AchievementType,
        isUnlocked: Bool = false, unlockedAt: Date? = nil, level: Int = 1, progress: Int = 0,
        target: Int = 1
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.level = level
        self.progress = progress
        self.target = target
    }

    mutating func unlock() {
        if !isUnlocked {
            isUnlocked = true
            unlockedAt = Date()
        }
    }

    // 获取成就的目标值（根据类型和等级）
    static func getTarget(for type: AchievementType, level: Int) -> Int {
        switch type {
        case .consecutive7Days:
            return 7 * level  // LV1: 7天, LV2: 14天, LV3: 21天...
        case .consecutive30Days:
            return 30 * level  // LV1: 30天, LV2: 60天...
        case .summerGrowth:
            return 100 * level  // LV1: 100成长值, LV2: 200...
        case .firstFriend:
            return level  // LV1: 1个好友, LV2: 2个...
        case .friendLike:
            return 2 * level  // LV1: 2次, LV2: 4次...
        case .storePlant:
            return level  // LV1: 1家店, LV2: 2家...
        case .totalCheckins:
            return 10 * level  // LV1: 10次, LV2: 20次...
        }
    }

    // 获取成就的最大等级
    static func maxLevel(for type: AchievementType) -> Int {
        switch type {
        case .consecutive7Days, .consecutive30Days:
            return 10  // 最多10级
        case .summerGrowth, .firstFriend, .friendLike, .storePlant, .totalCheckins:
            return 5  // 最多5级
        }
    }
}
