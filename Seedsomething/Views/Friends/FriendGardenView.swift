//
//  FriendGardenView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI
import _Concurrency

struct FriendGardenView: View {
    let friend: Friend
    @EnvironmentObject var plantManager: PlantManager
    @Environment(\.dismiss) var dismiss
    @State private var friendGrass: Grass?
    @State private var isLoading = true
    @State private var showSunshineEffect = false
    @State private var isLiking = false  // 正在点赞中
    @State private var hasLikedToday = false  // 今天是否已点赞
    @State private var showSuccessMessage = false  // 显示成功消息
    @State private var showErrorMessage = false  // 显示错误消息
    @State private var errorMessage = ""  // 错误消息内容

    var body: some View {
        ZStack {
            // 背景与季节一致，或者默认
            Color.brandLightGreen.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let grass = friendGrass {
                VStack {
                    // 顶部导航栏
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.brandDarkGray.opacity(0.6))
                        }
                        Spacer()
                        Text("\(friend.friendNickname) 的花園")
                            .font(.custom("PingFang TC", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.brandDarkGray)
                        Spacer()
                        // 占位
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .opacity(0)
                    }
                    .padding()

                    Spacer()

                    // 中间：朋友的草
                    ZStack {
                        // 光晕
                        if grass.level >= 5 {
                            Circle()
                                .fill(Color.brandLightGreen.opacity(0.2))
                                .frame(width: 200, height: 200)
                                .blur(radius: 20)
                        }

                        // 显示草的形态
                        let species = grass.plantSpecies ?? PlantRandomizer.deterministicPlant(for: grass.userId)
                        
                        PlantImageView(
                            plantSpecies: species,
                            level: grass.level,
                            size: 200
                        )
                        .scaleEffect(showSunshineEffect ? 1.1 : 1.0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6), value: showSunshineEffect)

                        // 阳光特效粒子
                        if showSunshineEffect {
                            ForEach(0..<8) { _ in
                                Image(systemName: "sun.max.fill")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                    .offset(
                                        x: CGFloat.random(in: -50...50),
                                        y: CGFloat.random(in: -50...50)
                                    )
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }

                    VStack(spacing: 8) {
                        Text("Lv.\(grass.level)")
                            .font(.custom("PingFang TC", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.brandDarkGray)

                        Text(grass.mood.displayName)
                            .font(.custom("PingFang TC", size: 16))
                            .foregroundColor(.brandDarkGray.opacity(0.8))
                    }
                    .padding(.top, 30)

                    Spacer()

                    // 底部互动栏
                    HStack(spacing: 40) {
                        // 点赞按钮
                        Button(action: giveLike) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            hasLikedToday
                                                ? Color.green.opacity(0.2)
                                                : Color.orange.opacity(0.1)
                                        )
                                        .frame(width: 60, height: 60)

                                    if isLiking {
                                        ProgressView()
                                            .progressViewStyle(
                                                CircularProgressViewStyle(tint: .orange))
                                    } else {
                                        Image(systemName: hasLikedToday ? "heart.fill" : "heart")
                                            .font(.title)
                                            .foregroundColor(hasLikedToday ? .green : .orange)
                                    }
                                }

                                Text(hasLikedToday ? "已點讚" : "點讚")
                                    .font(.custom("PingFang TC", size: 14))
                                    .foregroundColor(.brandDarkGray)
                            }
                        }
                        .disabled(isLiking || hasLikedToday)
                        .opacity((isLiking || hasLikedToday) ? 0.6 : 1.0)

                        // 留言（占位）
                        Button(action: {}) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "text.bubble.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                }

                                Text("留言")
                                    .font(.custom("PingFang TC", size: 14))
                                    .foregroundColor(.brandDarkGray)
                            }
                        }
                        .disabled(true)  // MVP 暂未实现
                        .opacity(0.5)
                    }
                    .padding(.bottom, 50)
                }
            } else {
                Text("無法加載花園數據")
                    .foregroundColor(.gray)
            }
        }
        .alert("點讚成功", isPresented: $showSuccessMessage) {
            Button("確定", role: .cancel) {}
        } message: {
            Text("已為 \(friend.friendNickname) 點讚！")
        }
        .alert("錯誤", isPresented: $showErrorMessage) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadFriendGrass()
            checkLikeStatus()
        }
    }

    private func loadFriendGrass() {
        Task {
            await MainActor.run {  //修改内容：确保状态更新在主线程
                isLoading = true
            }
            do {
                if let grass = try await FirebaseService.shared.loadGrass(
                    userId: friend.friendUserId)
                {
                    await MainActor.run {  //修改内容
                        self.friendGrass = grass
                    }
                }
            } catch {
                print("加载朋友草失败: \(error)")
            }
            await MainActor.run {  //修改内容
                isLoading = false
            }
        }
    }

    private func checkLikeStatus() {
        Task {
            let today = Calendar.current.startOfDay(for: Date())
            let hasLiked = plantManager.friendInteractions.contains { interaction in
                interaction.toUserId == friend.friendUserId && interaction.type == .like
                    && interaction.createdAt >= today
            }

            await MainActor.run {
                hasLikedToday = hasLiked
            }
        }
    }

    // 点赞功能
    private func giveLike() {
        guard !isLiking && !hasLikedToday else { return }

        withAnimation {
            showSunshineEffect = true
        }

        isLiking = true

        Task {
            do {
                try await plantManager.interactWithFriend(
                    friendId: friend.friendUserId, type: .like)

                await MainActor.run {
                    hasLikedToday = true
                    isLiking = false
                    showSuccessMessage = true
                    showSunshineEffect = true  // Ensure effect shows
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showSunshineEffect = false
                }
            } catch {
                await MainActor.run {
                    isLiking = false
                    errorMessage = "點讚失敗：\(error.localizedDescription)"
                    showErrorMessage = true
                    showSunshineEffect = false
                }
            }
        }
    }
}
