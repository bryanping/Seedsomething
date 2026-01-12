//
//  TasksView.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject var plantManager: PlantManager
    @EnvironmentObject var authManager: AuthManager
    @State private var tasks: [UserTask] = []
    @State private var achievements: [Achievement] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brandCream
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // 标题
                        HStack {
                            Text("成長任務")
                                .font(.custom("PingFang TC", size: 24))
                                .fontWeight(.medium)
                                .foregroundColor(.brandDarkGray)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // 日常任务区域
                        VStack(alignment: .leading, spacing: 15) {
                            Text("日常任務")
                                .font(.custom("PingFang TC", size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.brandDarkGray)
                                .padding(.horizontal, 20)
                            
                            if tasks.isEmpty {
                                // 初始化默认任务
                                ForEach(TaskType.allCases.filter { $0 != .custom }, id: \.self) { type in
                                    TaskRow(task: UserTask(userId: authManager.currentUser?.id ?? "", type: type))
                                        .padding(.horizontal, 20)
                                }
                            } else {
                                ForEach(tasks.filter { $0.isEnabled }) { task in
                                    TaskRow(task: task)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        // 成就系统
                        VStack(alignment: .leading, spacing: 15) {
                            Text("成就")
                                .font(.custom("PingFang TC", size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.brandDarkGray)
                                .padding(.horizontal, 20)
                            
                            if achievements.isEmpty {
                                // 初始化默认成就
                                ForEach([
                                    AchievementType.consecutive7Days,
                                    AchievementType.consecutive30Days,
                                    AchievementType.summerGrowth,
                                    AchievementType.firstFriend,
                                    AchievementType.friendLike,
                                    AchievementType.storePlant
                                ], id: \.self) { type in
                                    AchievementRow(achievement: Achievement(userId: authManager.currentUser?.id ?? "", type: type))
                                        .padding(.horizontal, 20)
                                }
                            } else {
                                ForEach(achievements) { achievement in
                                    AchievementRow(achievement: achievement)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TaskRow: View {
    let task: UserTask
    @State private var isCompleted = false
    
    var body: some View {
        HStack(spacing: 15) {
            // 任务图标
            Image(systemName: task.type.icon)
                .foregroundColor(isCompleted ? .brandLightGreen : .brandGrayGreen)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(task.name)
                    .font(.custom("PingFang TC", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(.brandDarkGray)
                
                Text("完成可获得 +\(task.type.expReward) 成长值")
                    .font(.custom("PingFang TC", size: 12))
                    .foregroundColor(.brandDarkGray.opacity(0.6))
            }
            
            Spacer()
            
            // 完成按钮
            Button(action: {
                isCompleted.toggle()
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .brandLightGreen : .brandGrayGreen)
                    .font(.title3)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.brandGrayGreen.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            isCompleted = task.isCompletedToday
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 15) {
            // 成就图标
            Image(systemName: achievement.isUnlocked ? "star.fill" : "star")
                .foregroundColor(achievement.isUnlocked ? .brandLightGreen : .brandGrayGreen)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(achievement.type.displayName)
                    .font(.custom("PingFang TC", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(achievement.isUnlocked ? .brandDarkGray : .brandDarkGray.opacity(0.6))
                
                Text(achievement.type.description)
                    .font(.custom("PingFang TC", size: 12))
                    .foregroundColor(.brandDarkGray.opacity(0.6))
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Text("✓")
                    .foregroundColor(.brandLightGreen)
                    .font(.title3)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color.brandLightGreen.opacity(0.1) : Color.white)
                .shadow(color: Color.brandGrayGreen.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    TasksView()
        .environmentObject(PlantManager.shared)
        .environmentObject(AuthManager.shared)
}

