import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/linping/Desktop/活動歷/App項目文檔/種點什麼/Seedsomething/Seedsomething/ContentView.swift", line: 1)
//
//  ContentView.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: __designTimeString("#7660_0", fallback: "leaf.fill"))
                    Text(__designTimeString("#7660_1", fallback: "我的草"))
                }
                .tag(__designTimeInteger("#7660_2", fallback: 0))
            
            MapView()
                .tabItem {
                    Image(systemName: __designTimeString("#7660_3", fallback: "map.fill"))
                    Text(__designTimeString("#7660_4", fallback: "地圖"))
                }
                .tag(__designTimeInteger("#7660_5", fallback: 1))
            
            ProfileView()
                .tabItem {
                    Image(systemName: __designTimeString("#7660_6", fallback: "person.fill"))
                    Text(__designTimeString("#7660_7", fallback: "我的"))
                }
                .tag(__designTimeInteger("#7660_8", fallback: 2))
        }
        .accentColor(.brandLightGreen)
    }
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            Color.brandCream
                .ignoresSafeArea()
            
            VStack(spacing: __designTimeInteger("#7660_9", fallback: 30)) {
                Spacer()
                
                // Logo 區域
                VStack(spacing: __designTimeInteger("#7660_10", fallback: 20)) {
                    HandDrawnSproutView()
                        .frame(width: __designTimeInteger("#7660_11", fallback: 120), height: __designTimeInteger("#7660_12", fallback: 120))
                    
                    Text(__designTimeString("#7660_13", fallback: "種點什麼"))
                        .font(.custom(__designTimeString("#7660_14", fallback: "PingFang TC"), size: __designTimeInteger("#7660_15", fallback: 32)))
                        .fontWeight(.medium)
                        .foregroundColor(.brandDarkGray)
                    
                    Text(__designTimeString("#7660_16", fallback: "讓生活發芽"))
                        .font(.custom(__designTimeString("#7660_17", fallback: "PingFang TC"), size: __designTimeInteger("#7660_18", fallback: 18)))
                        .foregroundColor(.brandDarkGreen)
                        .padding(.top, __designTimeInteger("#7660_19", fallback: -10))
                    
                    Text(__designTimeString("#7660_20", fallback: "每一步，都在種下你的回憶"))
                        .font(.custom(__designTimeString("#7660_21", fallback: "PingFang TC"), size: __designTimeInteger("#7660_22", fallback: 14)))
                        .foregroundColor(.brandDarkGray.opacity(__designTimeFloat("#7660_23", fallback: 0.7)))
                        .padding(.top, __designTimeInteger("#7660_24", fallback: 5))
                }
                
                Spacer()
                
                // 登入按鈕
                VStack(spacing: __designTimeInteger("#7660_25", fallback: 15)) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                let userIdentifier = appleIDCredential.user
                                let fullName = appleIDCredential.fullName
                                let nickname = fullName?.givenName ?? fullName?.familyName ?? __designTimeString("#7660_26", fallback: "新草")
                                let user = User(id: userIdentifier, nickname: nickname)
                                authManager.currentUser = user
                                authManager.isAuthenticated = __designTimeBoolean("#7660_27", fallback: true)
                            }
                        case .failure(let error):
                            print("登入失敗: \(error.localizedDescription)")
                        }
                    }
                    .frame(height: __designTimeInteger("#7660_28", fallback: 50))
                    .cornerRadius(__designTimeInteger("#7660_29", fallback: 12))
                    
                    Button(action: {
                        authManager.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: __designTimeString("#7660_30", fallback: "globe"))
                            Text(__designTimeString("#7660_31", fallback: "使用 Google 登入"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: __designTimeInteger("#7660_32", fallback: 50))
                        .background(Color.white)
                        .foregroundColor(.brandDarkGray)
                        .cornerRadius(__designTimeInteger("#7660_33", fallback: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: __designTimeInteger("#7660_34", fallback: 12))
                                .stroke(Color.brandGrayGreen, lineWidth: __designTimeInteger("#7660_35", fallback: 1))
                        )
                    }
                }
                .padding(.horizontal, __designTimeInteger("#7660_36", fallback: 40))
                .padding(.bottom, __designTimeInteger("#7660_37", fallback: 50))
            }
        }
    }
}

// 手繪小芽視圖（簡化版，實際應該使用 SVG 或手繪圖片）
struct HandDrawnSproutView: View {
    var body: some View {
        ZStack {
            // 背景圓圈
            Circle()
                .stroke(Color.brandLightGreen.opacity(__designTimeFloat("#7660_38", fallback: 0.3)), lineWidth: __designTimeInteger("#7660_39", fallback: 2))
                .frame(width: __designTimeInteger("#7660_40", fallback: 100), height: __designTimeInteger("#7660_41", fallback: 100))
            
            // 小芽
            Path { path in
                // 左葉
                path.move(to: CGPoint(x: __designTimeInteger("#7660_42", fallback: 40), y: __designTimeInteger("#7660_43", fallback: 60)))
                path.addQuadCurve(to: CGPoint(x: __designTimeInteger("#7660_44", fallback: 20), y: __designTimeInteger("#7660_45", fallback: 40)), control: CGPoint(x: __designTimeInteger("#7660_46", fallback: 25), y: __designTimeInteger("#7660_47", fallback: 50)))
                path.addQuadCurve(to: CGPoint(x: __designTimeInteger("#7660_48", fallback: 40), y: __designTimeInteger("#7660_49", fallback: 60)), control: CGPoint(x: __designTimeInteger("#7660_50", fallback: 30), y: __designTimeInteger("#7660_51", fallback: 50)))
                
                // 右葉
                path.move(to: CGPoint(x: __designTimeInteger("#7660_52", fallback: 60), y: __designTimeInteger("#7660_53", fallback: 60)))
                path.addQuadCurve(to: CGPoint(x: __designTimeInteger("#7660_54", fallback: 80), y: __designTimeInteger("#7660_55", fallback: 40)), control: CGPoint(x: __designTimeInteger("#7660_56", fallback: 75), y: __designTimeInteger("#7660_57", fallback: 50)))
                path.addQuadCurve(to: CGPoint(x: __designTimeInteger("#7660_58", fallback: 60), y: __designTimeInteger("#7660_59", fallback: 60)), control: CGPoint(x: __designTimeInteger("#7660_60", fallback: 70), y: __designTimeInteger("#7660_61", fallback: 50)))
                
                // 莖
                path.move(to: CGPoint(x: __designTimeInteger("#7660_62", fallback: 50), y: __designTimeInteger("#7660_63", fallback: 60)))
                path.addQuadCurve(to: CGPoint(x: __designTimeInteger("#7660_64", fallback: 50), y: __designTimeInteger("#7660_65", fallback: 80)), control: CGPoint(x: __designTimeInteger("#7660_66", fallback: 45), y: __designTimeInteger("#7660_67", fallback: 70)))
            }
            .stroke(Color.brandDarkGreen, lineWidth: __designTimeInteger("#7660_68", fallback: 3))
            .fill(Color.brandLightGreen)
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
               .environmentObject(PlantManager.shared)
}
