//
//  BrandColors.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI

extension Color {
    // 品牌顏色系統
    static let brandLightGreen = Color(hex: "#A8E6A3") // 主綠（嫩芽）
    static let brandDarkGreen = Color(hex: "#6A9E58") // 深綠（葉脈）
    static let brandDarkGray = Color(hex: "#4A4A4A") // 深灰（手繪線條）
    static let brandCream = Color(hex: "#FAF7EF") // 奶油白（手帳紙質）
    static let brandGrayGreen = Color(hex: "#BFD6BF") // 灰綠（次要背景）
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

