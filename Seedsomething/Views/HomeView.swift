//
//  HomeView.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var plantManager: PlantManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var isCheckingIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showWateringAnimation = false
    // @State private var currentSeason: Season = .current() // 移除本地 State，使用 SettingsManager
    @State private var currentTipIndex = 0  // 当前显示的 tip 索引
    @State private var tipUpdateTimer: Timer?  // 每小时更新 tip 的定时器
    @State private var showDiary = false  // 显示日记界面

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    // 季節背景（移至 ScrollView 內以隨內容捲動）
                    seasonBackground
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        // 顶部问候（简化）
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("我的草")
                                    .font(.custom("PingFang TC", size: 20))
                                    .fontWeight(.medium)
                                    .foregroundColor(.brandDarkGray)
                            }
                            Spacer()

                            // 季节标识
                            Text(settingsManager.currentSeason.displayName)
                                .font(.custom("PingFang TC", size: 14))
                                .foregroundColor(.brandDarkGray.opacity(0.7))

                            // 日记按钮
                            Button(action: {
                                showDiary = true
                            }) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.brandDarkGray)
                                    .padding(8)
                                    .background(Circle().fill(Color.white.opacity(0.6)))
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        // 中心：我的草（手绘风格）
                        VStack(spacing: 20) {
                            ZStack {
                                // 季节特效
                                if settingsManager.currentSeason == .summer {
                                    // 光点特效
                                    ForEach(0..<3, id: \.self) { _ in
                                        Circle()
                                            .fill(Color.yellow.opacity(0.3))
                                            .frame(width: 4, height: 4)
                                            .offset(
                                                x: CGFloat.random(in: -30...30),
                                                y: CGFloat.random(in: -30...30))
                                    }
                                }

                                // 草的主体
                                if let grass = plantManager.grass {
                                    // 植物种类，显示植物图片
                                    // 确保总是显示植物图片，如果没有种类则根据 userId 随机生成
                                    let species =
                                        grass.plantSpecies
                                        ?? PlantRandomizer.deterministicPlant(for: grass.userId)
                                    PlantImageView(
                                        plantSpecies: species,
                                        level: grass.level,
                                        mutationLevel: grass.mutationLevel,
                                        size: 150
                                    )

                                    // 奇迹消息显示
                                    if let message = plantManager.recentMutationMessage {
                                        Text(message)
                                            .font(.custom("PingFang TC", size: 14))
                                            .italic()
                                            .foregroundColor(.brandDarkGray.opacity(0.8))
                                            .transition(
                                                .opacity.combined(with: .move(edge: .top))
                                            )
                                            .padding(.top, 100)  // 放在草的下方一点
                                            .onAppear {
                                                // 几秒后自动消失
                                                DispatchQueue.main.asyncAfter(
                                                    deadline: .now() + 5
                                                ) {
                                                    withAnimation {
                                                        plantManager.recentMutationMessage = nil
                                                    }
                                                }
                                            }
                                    }

                                    // 浇水动画效果 (SpriteSheet)
                                    if showWateringAnimation {
                                        SpriteView(
                                            imageName: "WateringAnim",
                                            frameCount: 4,
                                            duration: 0.8,
                                            loop: true  // 循环播放直到逻辑结束
                                        )
                                        .frame(width: 80, height: 80)
                                        .offset(y: -50)  // 调整位置到草上方
                                    }
                                } else {
                                    // 没有草时显示 "重下你的种子"
                                    Button(action: {
                                        Task {
                                            await plantManager.plantRandomSeed()
                                        }
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "leaf.circle")
                                                .font(.system(size: 60))
                                                .foregroundColor(.brandLightGreen)

                                            Text("重下你的種子")
                                                .font(.custom("PingFang TC", size: 18))
                                                .fontWeight(.medium)
                                                .foregroundColor(.brandDarkGray)
                                        }
                                        .padding(30)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.6))
                                                .shadow(
                                                    color: Color.brandGrayGreen.opacity(0.1),
                                                    radius: 10, x: 0, y: 5)
                                        )
                                    }
                                }
                            }
                            .padding(.vertical, 30)

                            // 成长信息（持续显示，不随浇水状态改变）
                            VStack(spacing: 12) {
                                if let grass = plantManager.grass {
                                    // 草龄和连续天数
                                    HStack(spacing: 15) {
                                        Label(
                                            "草龄 \(grass.ageInDays) 天", systemImage: "calendar")
                                        Label(
                                            "连续 \(grass.consecutiveDays) 天",
                                            systemImage: "flame.fill")
                                    }
                                    .font(.custom("PingFang TC", size: 12))
                                    .foregroundColor(.brandDarkGray.opacity(0.7))

                                    // 小草 mood（天气状态）
                                    HStack(spacing: 5) {
                                        Text(grass.mood.emoji)
                                        Text(grass.mood.displayName)
                                    }
                                    .font(.custom("PingFang TC", size: 14))
                                    .foregroundColor(.brandDarkGray.opacity(0.8))

                                    // 成长条（非常细、半透明）
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.brandDarkGray.opacity(0.1))
                                                .frame(height: 3)

                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.brandLightGreen.opacity(0.6))
                                                .frame(
                                                    width: geometry.size.width
                                                        * grass.expPercentage, height: 3)
                                        }
                                    }
                                    .frame(height: 3)
                                    .frame(width: 200)
                                } else {
                                    // 没有草时不显示成长信息
                                    Text("期待新生命的開始...")
                                        .font(.custom("PingFang TC", size: 14))
                                        .foregroundColor(.brandDarkGray.opacity(0.5))
                                        .padding(.vertical, 10)
                                }

                                // Tip 提示（可点击切换，每小时自动切换）- 只显示一次
                                TipView(currentTipIndex: $currentTipIndex)
                            }
                        }
                        .padding(.vertical, 20)

                        // 浇水按钮（Water）= 打卡动作（固定显示）
                        // 如果没有草，隐藏或禁用浇水按钮
                        if plantManager.grass != nil {
                            VStack(spacing: 15) {
                                Button(action: {
                                    waterGrass()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "drop.fill")
                                            .font(.title3)
                                        Text(
                                            plantManager.grass?.hasCheckedInToday == true
                                                ? "今日已浇水" : "浇水"
                                        )
                                        .font(.custom("PingFang TC", size: 18))
                                        .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 55)
                                    .background(
                                        plantManager.grass?.hasCheckedInToday == true
                                            ? Color.brandGrayGreen
                                            : Color.brandLightGreen
                                    )
                                    .cornerRadius(16)
                                    .shadow(
                                        color: Color.brandLightGreen.opacity(0.3), radius: 10,
                                        x: 0, y: 5)
                                }
                                .disabled(
                                    plantManager.grass?.hasCheckedInToday == true
                                        || isCheckingIn
                                )
                                .opacity(
                                    plantManager.grass?.hasCheckedInToday == true ? 0.6 : 1.0)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        } else {
                            // 占位，保持布局
                            Color.clear.frame(height: 75)
                        }

                        // 好友的草（小角落轻松滑动查看）
                        if !plantManager.friends.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("好友的草")
                                    .font(.custom("PingFang TC", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(.brandDarkGray)
                                    .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(Array(plantManager.friends.prefix(5))) {
                                            friend in
                                            FriendGrassCard(friend: friend)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 20)
                        }

                        // 每日任务列表（提高位置，缩小卡片）
                        VStack(alignment: .leading, spacing: 8) {
                            Text("每日任務")
                                .font(.custom("PingFang TC", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(.brandDarkGray)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(plantManager.tasks.filter { $0.type != .custom }) {
                                        task in
                                        TaskCard(task: task)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            }
                        }
                        .padding(.top, 20)

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("錯誤", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // currentSeason = .current() // 不再需要
                if var grass = plantManager.grass {
                    grass.updateForSeason(settingsManager.currentSeason)
                    plantManager.grass = grass
                }
                // 后台自动检测日常任务
                plantManager.checkDailyTasks()

                // 初始化 tip 索引（基于当前小时）
                setupTipRotation()

                // 启动每小时自动切换 tip 的定时器
                startTipTimer()
            }
            .onDisappear {
                // 停止定时器
                tipUpdateTimer?.invalidate()
                tipUpdateTimer = nil
            }

        }
        .sheet(isPresented: $showDiary) {
            DiaryView()
        }
    }

    private var seasonBackground: some View {
        let imageName: String = {
            switch settingsManager.currentSeason {
            case .spring: return "HomeView_sp"
            case .summer: return "HomeView_sm"
            case .autumn: return "HomeView_fl"
            case .winter: return "HomeView_wi"
            }
        }()

        return Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }

    private func waterGrass() {
        isCheckingIn = true
        showWateringAnimation = true

        Task {
            do {
                try await plantManager.checkIn()

                // 浇水动画持续1秒
                try await Task.sleep(nanoseconds: 1_000_000_000)
                showWateringAnimation = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                showWateringAnimation = false
            }
            isCheckingIn = false
        }
    }

    // 设置 tip 索引（基于当前小时）
    private func setupTipRotation() {
        let hour = Calendar.current.component(.hour, from: Date())
        // 根据当前小时选择 tip（24 个 tip，每小时一个）
        currentTipIndex = hour % TipData.tips.count
    }

    // 启动每小时自动切换 tip 的定时器
    private func startTipTimer() {
        // 计算到下一个整点的时间
        let calendar = Calendar.current
        let now = Date()

        // 获取当前小时的开始时间（将分钟、秒、纳秒设为0）
        let currentHourStart = calendar.date(
            bySettingHour: calendar.component(.hour, from: now),
            minute: 0,
            second: 0,
            of: now)!

        // 计算下一个整点
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: currentHourStart)!
        let timeInterval = nextHour.timeIntervalSince(now)

        // 先设置一个定时器到下一个整点
        tipUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) {
            [self] _ in
            // 切换到下一个 tip
            currentTipIndex = (currentTipIndex + 1) % TipData.tips.count

            // 然后每小时切换一次
            tipUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) {
                [self] _ in
                currentTipIndex = (currentTipIndex + 1) % TipData.tips.count
            }
        }
    }
}

// Tip 数据
struct TipData {
    static let tips: [String] = [
        "每天限定一次，额外任务可补充次数",
        "连续打卡可以获得更多成长值",
        "在地图上种草可以查看附近的小草",
        "完成每日任务可以获得额外经验",
        "添加好友可以互相查看小草状态",
        "小草等级越高，扩张范围越大",
        "不同季节小草会有不同的外观",
        "连续30天打卡可以获得露珠装饰",
        "在地图上可以添加附近的好友",
        "浇水后小草会获得基础成长值",
        "完成所有每日任务可以获得奖励",
        "好友之间可以互相晒太阳帮助成长",
        "小草的心情会根据打卡状态变化",
        "等级越高，小草的高度也会增加",
        "在地图上可以看到所有用户的打卡点",
        "每天最多可以在地图上种草99次",
        "季节变化会影响小草的外观和状态",
        "连续打卡天数越多，奖励越丰富",
        "完成成就任务可以解锁特殊徽章",
        "地图上的小草会显示用户信息",
        "添加好友后可以随时查看他们的草",
        "小草的状态会反映你的打卡习惯",
        "定期浇水可以让小草保持健康状态",
        "探索地图可以发现更多有趣的小草",
    ]
}

// Tip 视图（可点击切换）
struct TipView: View {
    @Binding var currentTipIndex: Int

    var body: some View {
        Button(action: {
            // 点击切换到下一个 tip
            currentTipIndex = (currentTipIndex + 1) % TipData.tips.count
        }) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)

                Text(TipData.tips[currentTipIndex])
                    .font(.custom("PingFang TC", size: 12))
                    .foregroundColor(.brandDarkGray.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Image(systemName: "chevron.right")
                    .foregroundColor(.brandDarkGray.opacity(0.5))
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 浇水动画已替换为 SpriteView

// 好友的草卡片
struct FriendGrassCard: View {
    let friend: Friend

    var body: some View {
        VStack(spacing: 8) {
            // 根据好友ID生成植物图片
            let species = PlantRandomizer.deterministicPlant(for: friend.friendUserId)
            PlantIconView(
                plantSpecies: species,
                size: 50
            )

            Text(friend.friendNickname)
                .font(.custom("PingFang TC", size: 12))
                .foregroundColor(.brandDarkGray)
                .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.brandGrayGreen.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .frame(width: 80)
    }
}

// 每日任务卡片（缩小版）
struct TaskCard: View {
    let task: UserTask

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: task.type.icon)
                .font(.title3)
                .foregroundColor(
                    task.isCompletedToday ? .brandLightGreen : .brandDarkGray.opacity(0.5))

            Text(task.type.displayName)
                .font(.custom("PingFang TC", size: 11))
                .foregroundColor(.brandDarkGray)
                .lineLimit(1)

            if task.isCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.brandLightGreen)
            }
        }
        .frame(width: 65, height: 75)  // 缩小卡片尺寸
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(task.isCompletedToday ? Color.brandLightGreen.opacity(0.1) : Color.white)
                .shadow(color: Color.brandGrayGreen.opacity(0.1), radius: 3, x: 0, y: 1)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(PlantManager.shared)
        .environmentObject(AuthManager.shared)
}
