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
    @State private var newNickname = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brandCream
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // 頭像與基本資訊
                        VStack(spacing: 15) {
                            HandDrawnSproutView()
                                .frame(width: 80, height: 80)
                            
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
                        
                        // 功能列表
                        VStack(spacing: 12) {
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
                                // TODO: 設定頁面
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
                QRScannerView()
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

