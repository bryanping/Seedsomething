//
//  MapPinView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI

struct MapPinView: View {
    let level: Int
    let isZoomedOut: Bool // 缩放策略：是否是远景
    
    // 逻辑：
    // Lv 1-3: Grass (Frame 0)
    // Lv 4-6: Plant (Frame 1)
    // Lv 7-10: Tree (Frame 2)
    
    var body: some View {
        if isZoomedOut {
            // 远景模式：统一显示为小点（简化版 Grass）
            Circle()
                .fill(Color.brandLightGreen)
                .frame(width: 8, height: 8)
                .shadow(radius: 1)
        } else {
            // 近景模式：显示真实形态
            mainPinContent
        }
    }
    
    private var mainPinContent: some View {
        ZStack {
            // Lv10 特殊光晕
            if level >= 10 {
                Circle()
                    .fill(Color.brandLightGreen.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .blur(radius: 5)
            }
            
            // 基础精灵图
            SpriteFrameView(
                imageName: "plant_stages",
                frameIndex: frameIndex,
                totalFrames: 3
            )
            .frame(width: size, height: size)
            .shadow(radius: 2, y: 2)
        }
    }
    
    // 根据等级计算使用第几帧
    private var frameIndex: Int {
        switch level {
        case 1...3: return 0 // Grass
        case 4...6: return 1 // Plant
        default: return 2    // Tree (7+)
        }
    }
    
    // 根据等级微调尺寸
    private var size: CGFloat {
        // 基础尺寸 40
        // Lv 1-3: 0.8x ~ 1.0x -> 32 ~ 40
        // Lv 4-6: 1.0x ~ 1.2x -> 40 ~ 48
        // Lv 7-10: 1.2x ~ 1.4x -> 48 ~ 56
        
        let baseSize: CGFloat = 40
        
        switch level {
        case 1...3:
            return baseSize * (0.8 + CGFloat(level - 1) * 0.1)
        case 4...6:
            return baseSize * (1.0 + CGFloat(level - 4) * 0.1)
        default: // 7+
            let cappedLevel = min(level, 10)
            return baseSize * (1.2 + CGFloat(cappedLevel - 7) * 0.05)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        MapPinView(level: 1, isZoomedOut: false)
        MapPinView(level: 5, isZoomedOut: false)
        MapPinView(level: 10, isZoomedOut: false)
        MapPinView(level: 10, isZoomedOut: true)
    }
}
