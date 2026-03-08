//
//  ProfileView.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var plantManager: PlantManager
    @State private var showQRScanner = false
    @State private var showStoreGarden = false
    @State private var showEditNickname = false
    @State private var showSettings = false // 新增 Settings 状态
    @State private var showFriendsList = false // 新增 FriendsList 状态
    @State private var showAchievements = false
    @State private var newNickname = ""
    @State private var isPlantAnimating = false // 控制植物点击动画
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brandCream
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // 頭像與基本資訊
                        VStack(spacing: 15) {
                            if let grass = plantManager.grass {
                                ZStack {
                                    // 背景光晕
                                    Circle()
                                        .fill(Color.brandLightGreen.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .scaleEffect(isPlantAnimating ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.3), value: isPlantAnimating)
                                    
                                    // 植物图鉴（随机生成的植物）
                                    if let species = grass.plantSpecies {
                                        PlantImageView(plantSpecies: species, level: grass.level, size: 80)
                                            .scaleEffect(isPlantAnimating ? 1.2 : 1.0)
                                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPlantAnimating)
                                            .onTapGesture {
                                                // 点击播放小动画
                                                isPlantAnimating = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    isPlantAnimating = false
                                                }
                                            }
                                        
                                        // 植物名称
                                        Text(species.displayName)
                                            .font(.custom("PingFang TC", size: 12))
                                            .foregroundColor(.brandDarkGreen)
                                            .padding(.top, -5)
                                    } 
                                }
                            } 
                            
                            Text(authManager.currentUser?.nickname ?? "草")
                                .font(.custom("PingFang TC", size: 24))
                                .fontWeight(.medium)
                                .foregroundColor(.brandDarkGray)
                            
                            if let grass = plantManager.grass {
                                Text("Lv.\(grass.level) • 總打卡 \(grass.totalCheckinCount) 次")
                                    .font(.custom("PingFang TC", size: 14))
                                    .foregroundColor(.brandDarkGray.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 30)
                        
                        // 統計卡片
                        VStack(spacing: 15) {
                            StatCard(title: "總種草次數", value: "\(plantManager.plantRecords.count)")
                            StatCard(title: "店家種草次數", value: "\(plantManager.plantRecords.filter { $0.type == .storeScan }.count)")
                            StatCard(title: "足跡地點數", value: "\(uniqueLocationsCount)")
                        }
                        .padding(.horizontal, 20)
                        
                        // 成就系统
                        VStack(alignment: .leading, spacing: 15) {
                            Text("成就獎章")
                                .font(.custom("PingFang TC", size: 20))
                                .fontWeight(.medium)
                                .foregroundColor(.brandDarkGray)
                                .padding(.horizontal, 20)
                            
                            if plantManager.achievements.isEmpty {
                                // 初始化默认成就
                                ForEach([
                                    AchievementType.consecutive7Days,
                                    AchievementType.consecutive30Days,
                                    AchievementType.summerGrowth,
                                    AchievementType.firstFriend,
                                    AchievementType.friendLike,
                                    AchievementType.storePlant
                                ], id: \.self) { type in
                                    AchievementBadgeView(
                                        achievement: Achievement(
                                            userId: authManager.currentUser?.id ?? "",
                                            type: type
                                        ),
                                        plantManager: plantManager
                                    )
                                    .padding(.horizontal, 20)
                                }
                            } else {
                                ForEach(plantManager.achievements) { achievement in
                                    AchievementBadgeView(
                                        achievement: achievement,
                                        plantManager: plantManager
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        // 功能列表
                        VStack(spacing: 12) {
                            ProfileMenuItem(
                                icon: "star.fill",
                                title: "成就",
                                color: .orange
                            ) {
                                showAchievements = true
                            }

                            ProfileMenuItem(
                                icon: "person.2.fill",
                                title: "我的好友",
                                color: .blue
                            ) {
                                showFriendsList = true
                            }
                            
                            ProfileMenuItem(
                                icon: "qrcode.viewfinder",
                                title: "掃描店家 QR 種草",
                                color: .brandLightGreen
                            ) {
                                showQRScanner = true
                            }
                            
                            ProfileMenuItem(
                                icon: "leaf.fill",
                                title: plantManager.stores.isEmpty ? "成為店家" : "管理我的店家花園",
                                color: .brandDarkGreen
                            ) {
                                showStoreGarden = true
                            }
                            
                            ProfileMenuItem(
                                icon: "pencil",
                                title: "編輯暱稱",
                                color: .brandGrayGreen
                            ) {
                                newNickname = authManager.currentUser?.nickname ?? ""
                                showEditNickname = true
                            }
                            
                            ProfileMenuItem(
                                icon: "gear",
                                title: "設定",
                                color: .brandDarkGray.opacity(0.6)
                            ) {
                                showSettings = true
                            }
                            
                            ProfileMenuItem(
                                icon: "arrow.right.square",
                                title: "登出",
                                color: .red.opacity(0.7)
                            ) {
                                authManager.signOut()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showQRScanner) {
                AddFriendQRScannerView { _ in } //修改内容：使用改名后的 View，闭包参数正常
            }

            .sheet(isPresented: $showFriendsList) {
                FriendsListView()
            }
            .sheet(isPresented: $showStoreGarden) {
                StoreGardenView()
            }
            .sheet(isPresented: $showEditNickname) {
                EditNicknameView(nickname: $newNickname) {
                    if var user = authManager.currentUser {
                        user.nickname = newNickname
                        authManager.currentUser = user
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
        }
    }
    
    private var uniqueLocationsCount: Int {
        let locations = Set(plantManager.plantRecords.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" })
        return locations.count
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("PingFang TC", size: 16))
                .foregroundColor(.brandDarkGray)
            
            Spacer()
            
            Text(value)
                .font(.custom("PingFang TC", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.brandDarkGreen)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.brandGrayGreen.opacity(0.2), radius: 8, x: 0, y: 3)
        )
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.custom("PingFang TC", size: 16))
                    .foregroundColor(.brandDarkGray)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.brandDarkGray.opacity(0.3))
                    .font(.system(size: 14))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.brandGrayGreen.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
    }
}

// 成就奖章视图（带LV等级）
struct AchievementBadgeView: View {
    let achievement: Achievement
    @ObservedObject var plantManager: PlantManager
    
    var body: some View {
        HStack(spacing: 15) {
            // 奖章图标（带LV标识）
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.brandLightGreen.opacity(0.2) : Color.brandGrayGreen.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 2) {
                    Image(systemName: achievement.isUnlocked ? "star.fill" : "star")
                        .foregroundColor(achievement.isUnlocked ? .brandLightGreen : .brandGrayGreen)
                        .font(.title3)
                    
                    // LV等级标识
                    Text("LV\(achievement.level)")
                        .font(.custom("PingFang TC", size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(achievement.isUnlocked ? .brandDarkGreen : .brandDarkGray.opacity(0.5))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(achievement.type.displayName)
                        .font(.custom("PingFang TC", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(achievement.isUnlocked ? .brandDarkGray : .brandDarkGray.opacity(0.6))
                    
                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.brandLightGreen)
                            .font(.system(size: 16))
                    }
                }
                
                Text(achievement.type.description)
                    .font(.custom("PingFang TC", size: 12))
                    .foregroundColor(.brandDarkGray.opacity(0.6))
                
                // 进度条
                if !achievement.isUnlocked {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.brandGrayGreen.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.brandLightGreen)
                                .frame(
                                    width: geometry.size.width * min(1.0, Double(achievement.progress) / Double(achievement.target)),
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)
                    
                    Text("進度: \(achievement.progress)/\(achievement.target)")
                        .font(.custom("PingFang TC", size: 10))
                        .foregroundColor(.brandDarkGray.opacity(0.5))
                } else {
                    Text("已達成 LV\(achievement.level)")
                        .font(.custom("PingFang TC", size: 12))
                        .foregroundColor(.brandLightGreen)
                }
            }
            
            Spacer()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color.brandLightGreen.opacity(0.05) : Color.white)
                .shadow(color: Color.brandGrayGreen.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct EditNicknameView: View {
    @Binding var nickname: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("輸入暱稱", text: $nickname)
                    .font(.custom("PingFang TC", size: 16))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.brandCream)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                
                Spacer()
                
                Button(action: {
                    onSave()
                    dismiss()
                }) {
                    Text("儲存")
                        .font(.custom("PingFang TC", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.brandLightGreen)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color.brandCream)
            .navigationTitle("編輯暱稱")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

