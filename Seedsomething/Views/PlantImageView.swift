//
//  PlantImageView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI

/// 植物图片显示组件
struct PlantImageView: View {
    let plantSpecies: PlantSpecies
    let stage: Int  // 生长阶段 1-5
    let mutationLevel: Int
    let size: CGFloat

    init(plantSpecies: PlantSpecies, level: Int? = nil, mutationLevel: Int = 0, size: CGFloat = 120)
    {
        self.plantSpecies = plantSpecies
        self.mutationLevel = mutationLevel
        if let level = level {
            self.stage = PlantSpecies.growthStage(for: level)
        } else {
            self.stage = 3  // 默认成熟阶段
        }
        self.size = size
    }

    var body: some View {
        Image(plantSpecies.imageName(for: stage, mutationLevel: mutationLevel))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

/// 植物图标视图（用于列表、成就等）
struct PlantIconView: View {
    let plantSpecies: PlantSpecies
    let mutationLevel: Int
    let size: CGFloat

    init(plantSpecies: PlantSpecies, mutationLevel: Int = 0, size: CGFloat = 40) {
        self.plantSpecies = plantSpecies
        self.mutationLevel = mutationLevel
        self.size = size
    }

    var body: some View {
        Image(plantSpecies.imageName(for: 3, mutationLevel: mutationLevel))  // 使用成熟阶段作为图标
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
