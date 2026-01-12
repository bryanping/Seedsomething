//
//  SpriteView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI

struct SpriteView: View {
    let imageName: String
    let frameCount: Int
    let duration: Double
    let loop: Bool
    
    // 如果是单行精灵图（所有帧在同一行），设为 true
    // 如果是单张图片包含所有帧（需要切割），这里假设是水平排列
    let isHorizontal: Bool = true
    
    @State private var currentFrame: Int = 0
    @State private var timer: Timer?
    @State private var isAnimating: Bool = false
    
    // 完成时的回调
    var onFinish: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                // 计算偏移量来显示当前帧
                // 假设图片宽度是 frameCount * 单帧宽度
                // 我们通过 visualEffect 或 offset 来实现
                // 但 SwiftUI Image 裁剪比较麻烦，更简单的做法是：
                // 使用 scaleEffect 和 offset 来只显示一部分
                
                // 更好的方法：如果图片预先切割好，使用 Image("frame_\(i)")
                // 但为了支持 SpriteSheet，我们使用 GeometryReader 裁剪
                .frame(width: geometry.size.width * CGFloat(frameCount), height: geometry.size.height)
                .offset(x: -geometry.size.width * CGFloat(currentFrame), y: 0)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                .clipped()
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        currentFrame = 0
        
        let interval = duration / Double(frameCount)
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if currentFrame < frameCount - 1 {
                currentFrame += 1
            } else {
                if loop {
                    currentFrame = 0
                } else {
                    stopAnimation()
                    onFinish?()
                }
            }
        }
    }
    
    private func stopAnimation() {
        isAnimating = false
        timer?.invalidate()
        timer = nil
    }
}

// 静态图片裁剪视图（用于地图图针）
struct SpriteFrameView: View {
    let imageName: String
    let frameIndex: Int
    let totalFrames: Int
    
    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width * CGFloat(totalFrames), height: geometry.size.height)
                .offset(x: -geometry.size.width * CGFloat(frameIndex), y: 0)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                .clipped()
        }
    }
}
