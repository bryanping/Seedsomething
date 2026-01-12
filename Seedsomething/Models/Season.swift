//
//  Season.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation

enum Season: String, Codable, CaseIterable {
    case spring = "spring"  // 春：嫩绿 & 小花
    case summer = "summer"  // 夏：浓绿 & 光点
    case autumn = "autumn"  // 秋：枯黄小花谢落
    case winter = "winter"  // 冬：覆霜、草穗隐藏
    
    var displayName: String {
        switch self {
        case .spring: return "春天"
        case .summer: return "夏天"
        case .autumn: return "秋天"
        case .winter: return "冬天"
        }
    }
    
    var primaryColor: String {
        switch self {
        case .spring: return "#A8E6A3" // 嫩绿
        case .summer: return "#6A9E58" // 浓绿
        case .autumn: return "#D4A574" // 枯黄
        case .winter: return "#E8E8E8" // 覆霜
        }
    }
    
    var hasFlower: Bool {
        switch self {
        case .spring, .summer: return true
        case .autumn, .winter: return false
        }
    }
    
    static func current() -> Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }
}

enum GrassMood: String, Codable {
    case sunny = "sunny"        // 晴朗
    case needsWater = "needs_water"  // 需要水
    case flowering = "flowering"     // 小花期
    
    var displayName: String {
        switch self {
        case .sunny: return "晴朗"
        case .needsWater: return "需要水"
        case .flowering: return "小花期"
        }
    }
    
    var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .needsWater: return "💧"
        case .flowering: return "🌸"
        }
    }
}

