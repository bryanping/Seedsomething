//
//  SproutAnimationView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI

struct SproutAnimationView: View {
    @Binding var isAnimationFinished: Bool
    @State private var currentFrameIndex = 1
    private let totalFrames = 6
    private let frameDuration = 0.15 // 每帧间隔秒数
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 底层背景图（始终显示，铺满全屏）
                Image("LoginView_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // 小芽生长动画（局部显示，放置在土壤上方）
                Image("LoginView_plen_\(currentFrameIndex)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150) // 调整小芽显示大小
                    .position(x: geometry.size.width * 0.49 , y: geometry.size.height * 0.46) // 调整位置：X居中，Y轴位置（0.45为偏上，请根据土壤位置微调）
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { timer in
            if currentFrameIndex < totalFrames {
                currentFrameIndex += 1
            } else {
                timer.invalidate()
                withAnimation(.easeIn(duration: 0.5)) {
                    isAnimationFinished = true
                }
            }
        }
    }
}

