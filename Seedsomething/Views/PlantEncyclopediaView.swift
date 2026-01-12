//
//  PlantEncyclopediaView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI

/// 植物图鉴视图
struct PlantEncyclopediaView: View {
    @State private var selectedCategory: PlantCategory? = nil
    @State private var searchText = ""
    @State private var selectedPlant: PlantSpecies? = nil
    
    private var filteredPlants: [PlantSpecies] {
        var plants = PlantSpecies.allCases
        
        // 按分类筛选
        if let category = selectedCategory {
            plants = plants.filter { $0.category == category }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            plants = plants.filter { $0.displayName.contains(searchText) }
        }
        
        return plants.sorted { $0.displayName < $1.displayName }
    }
    
    private var categories: [PlantCategory] {
        return PlantCategory.allCases
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 全部
                        CategoryChip(
                            title: "全部",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // 植物网格
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(filteredPlants) { plant in
                            PlantCard(plant: plant) {
                                selectedPlant = plant
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("植物图鉴")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant)
            }
        }
    }
}

/// 植物卡片
struct PlantCard: View {
    let plant: PlantSpecies
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                PlantIconView(plantSpecies: plant, size: 60)
                
                Text(plant.displayName)
                    .font(.custom("PingFang TC", size: 12))
                    .foregroundColor(.brandDarkGray)
                    .lineLimit(1)
                
                // 稀有度标识
                if plant.rarity != .common {
                    HStack(spacing: 4) {
                        Image(systemName: plant.rarity == .rare ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundColor(plant.rarity == .rare ? .yellow : .gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.brandGrayGreen.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 分类芯片
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("PingFang TC", size: 14))
                .foregroundColor(isSelected ? .white : .brandDarkGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.brandLightGreen : Color.white)
                )
        }
    }
}

/// 搜索栏
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.brandDarkGray.opacity(0.5))
            
            TextField("搜索植物...", text: $text)
                .font(.custom("PingFang TC", size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
    }
}

/// 植物详情视图
struct PlantDetailView: View {
    let plant: PlantSpecies
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 植物图片（展示所有生长阶段）
                    VStack(spacing: 16) {
                        Text("生长过程")
                            .font(.custom("PingFang TC", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.brandDarkGray)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(1...5, id: \.self) { stage in
                                    VStack(spacing: 8) {
                                        PlantImageView(plantSpecies: plant, level: nil, size: 100)
                                            .id(stage)
                                        
                                        Text("阶段 \(stage)")
                                            .font(.custom("PingFang TC", size: 12))
                                            .foregroundColor(.brandDarkGray.opacity(0.7))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    
                    // 植物信息
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(plant.displayName)
                                .font(.custom("PingFang TC", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.brandDarkGray)
                            
                            Spacer()
                            
                            // 稀有度标识
                            if plant.rarity != .common {
                                HStack(spacing: 4) {
                                    ForEach(0..<plant.rarity.rawValue, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                        }
                        
                        HStack {
                            Label(plant.category.displayName, systemImage: "leaf.fill")
                                .font(.custom("PingFang TC", size: 14))
                                .foregroundColor(.brandDarkGray.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .background(Color.brandCream.ignoresSafeArea())
            .navigationTitle("植物详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.custom("PingFang TC", size: 16))
                }
            }
        }
    }
}

// 扩展 PlantCategory 以支持 CaseIterable
extension PlantCategory: CaseIterable {
    static var allCases: [PlantCategory] {
        return [.beans, .vegetables, .ornamental, .trees, .flowers, .crops, .herbs]
    }
}

