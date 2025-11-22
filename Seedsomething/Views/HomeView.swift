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
    @State private var isCheckingIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brandCream
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // 頂部問候
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("早安，\(authManager.currentUser?.nickname ?? "草")")
                                    .font(.custom("PingFang TC", size: 24))
                                    .fontWeight(.medium)
                                    .foregroundColor(.brandDarkGray)
                                
                                Text("今天也要努力發芽 🌱")
                                    .font(.custom("PingFang TC", size: 14))
                                    .foregroundColor(.brandDarkGray.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // 草的形象與等級
                        if let grass = plantManager.grass {
                            VStack(spacing: 15) {
                                // 草的形象（根據等級顯示不同大小）
                                HandDrawnSproutView()
                                    .frame(width: CGFloat(80 + grass.level * 10),
                                          height: CGFloat(80 + grass.level * 10))
                                
                                // 等級與經驗條
                                VStack(spacing: 8) {
                                    Text("Lv.\(grass.level)")
                                        .font(.custom("PingFang TC", size: 20))
                                        .fontWeight(.bold)
                                        .foregroundColor(.brandDarkGreen)
                                    
                                    // 經驗條
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.brandGrayGreen.opacity(0.3))
                                                .frame(height: 12)
                                            
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.brandLightGreen)
                                                .frame(width: geometry.size.width * grass.expPercentage, height: 12)
                                        }
                                    }
                                    .frame(height: 12)
                                    .padding(.horizontal, 40)
                                    
                                    Text("EXP \(grass.exp) / \(Grass.expPerLevel)")
                                        .font(.custom("PingFang TC", size: 12))
                                        .foregroundColor(.brandDarkGray.opacity(0.6))
                                }
                            }
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: Color.brandGrayGreen.opacity(0.2), radius: 10, x: 0, y: 5)
                            )
                            .padding(.horizontal, 20)
                        } else {
                            // 還沒有草資料
                            VStack(spacing: 15) {
                                HandDrawnSproutView()
                                    .frame(width: 80, height: 80)
                                Text("開始你的種草之旅吧！")
                                    .font(.custom("PingFang TC", size: 16))
                                    .foregroundColor(.brandDarkGray.opacity(0.7))
                            }
                            .padding(.vertical, 40)
                        }
                        
                        // 打卡區塊
                        VStack(spacing: 15) {
                            Text("今日種草狀態")
                                .font(.custom("PingFang TC", size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.brandDarkGray)
                            
                            if let grass = plantManager.grass, grass.hasCheckedInToday {
                                VStack(spacing: 8) {
                                    Text("今日已種草 ✓")
                                        .font(.custom("PingFang TC", size: 16))
                                        .foregroundColor(.brandDarkGreen)
                                    
                                    Text("已連續 \(grass.consecutiveDays) 天")
                                        .font(.custom("PingFang TC", size: 14))
                                        .foregroundColor(.brandDarkGray.opacity(0.7))
                                }
                                .padding(.vertical, 15)
                            } else {
                                Text("今日尚未打卡")
                                    .font(.custom("PingFang TC", size: 16))
                                    .foregroundColor(.brandDarkGray.opacity(0.7))
                                    .padding(.vertical, 15)
                            }
                            
                            Button(action: {
                                checkIn()
                            }) {
                                Text(plantManager.grass?.hasCheckedInToday == true ? "今日已打卡" : "今日種草打卡")
                                    .font(.custom("PingFang TC", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        plantManager.grass?.hasCheckedInToday == true
                                            ? Color.brandGrayGreen
                                            : Color.brandLightGreen
                                    )
                                    .cornerRadius(12)
                            }
                            .disabled(plantManager.grass?.hasCheckedInToday == true || isCheckingIn)
                            .opacity(plantManager.grass?.hasCheckedInToday == true ? 0.6 : 1.0)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.brandGrayGreen.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                        
                        // 最近紀錄
                        VStack(alignment: .leading, spacing: 15) {
                            Text("最近種草記錄")
                                .font(.custom("PingFang TC", size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.brandDarkGray)
                                .padding(.horizontal, 20)
                            
                            if plantManager.plantRecords.isEmpty {
                                Text("還沒有種草記錄")
                                    .font(.custom("PingFang TC", size: 14))
                                    .foregroundColor(.brandDarkGray.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else {
                                ForEach(plantManager.plantRecords.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5)) { record in
                                    PlantRecordRow(record: record)
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
            .alert("錯誤", isPresented: $showError) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func checkIn() {
        isCheckingIn = true
        Task {
            do {
                try await plantManager.checkIn()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isCheckingIn = false
        }
    }
}

struct PlantRecordRow: View {
    let record: PlantRecord
    
    var body: some View {
        HStack(spacing: 15) {
            // 類型圖示
            Image(systemName: record.type == .personalCheckin ? "leaf.fill" : "qrcode")
                .foregroundColor(.brandLightGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(record.type == .personalCheckin ? "一般打卡" : "店家掃碼")
                    .font(.custom("PingFang TC", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.brandDarkGray)
                
                Text(formatDate(record.createdAt))
                    .font(.custom("PingFang TC", size: 12))
                    .foregroundColor(.brandDarkGray.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.brandGrayGreen.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
}



#Preview {
    HomeView()
}
