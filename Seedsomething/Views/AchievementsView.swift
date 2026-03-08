//
//  AchievementsView.swift
//  Seedsomething
//
//  成就頁面：展示全部成就、進度與數據統計
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var plantManager: PlantManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    private var displayAchievements: [Achievement] {
        if !plantManager.achievements.isEmpty {
            return plantManager.achievements
        }
        let userId = authManager.currentUser?.id ?? ""
        return AchievementType.allCasesForDisplay.map { type in
            Achievement(
                userId: userId,
                type: type,
                target: Achievement.getTarget(for: type, level: 1)
            )
        }
    }

    private var unlockedCount: Int {
        displayAchievements.filter(\.isUnlocked).count
    }

    private var totalLevels: Int {
        displayAchievements.reduce(0) { $0 + $1.level }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandCream
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 統計摘要
                        summarySection

                        // 成就列表
                        VStack(alignment: .leading, spacing: 12) {
                            Text("全部成就")
                                .font(.custom("PingFang TC", size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.brandDarkGray)
                                .padding(.horizontal, 20)

                            ForEach(displayAchievements) { achievement in
                                AchievementBadgeView(
                                    achievement: achievement,
                                    plantManager: plantManager
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") {
                        dismiss()
                    }
                    .foregroundColor(.brandDarkGreen)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: refreshAchievements) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.brandDarkGreen)
                    }
                }
            }
        }
        .onAppear {
            refreshAchievements()
        }
    }

    private var summarySection: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "已解鎖",
                value: "\(unlockedCount)/\(displayAchievements.count)",
                icon: "star.fill"
            )
            SummaryCard(
                title: "總等級",
                value: "LV\(totalLevels)",
                icon: "arrow.up.circle.fill"
            )
        }
        .padding(.horizontal, 20)
    }

    private func refreshAchievements() {
        plantManager.refreshAchievements()
    }
}

/// 成就類型枚舉的展示用全列表（與 PlantManager 中初始化順序一致）
extension AchievementType {
    static var allCasesForDisplay: [AchievementType] {
        [
            .consecutive7Days,
            .consecutive30Days,
            .summerGrowth,
            .firstFriend,
            .friendLike,
            .storePlant,
            .totalCheckins,
        ]
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.brandLightGreen)
            Text(value)
                .font(.custom("PingFang TC", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.brandDarkGreen)
            Text(title)
                .font(.custom("PingFang TC", size: 12))
                .foregroundColor(.brandDarkGray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.brandGrayGreen.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    AchievementsView()
        .environmentObject(PlantManager.shared)
        .environmentObject(AuthManager.shared)
}
