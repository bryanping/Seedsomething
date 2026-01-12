//
//  SettingsManager.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import Foundation
import SwiftUI

enum SeasonMode: String, Codable, CaseIterable {
    case auto = "auto"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .auto: return "自動 (跟隨月份)"
        case .manual: return "手動設定"
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("seasonMode") var seasonMode: SeasonMode = .auto
    @AppStorage("manualSeason") var manualSeason: Season = .spring
    
    // 当前生效的季节
    var currentSeason: Season {
        if seasonMode == .auto {
            return Season.current()
        } else {
            return manualSeason
        }
    }
    
    private init() {}
}
