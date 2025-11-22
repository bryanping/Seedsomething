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
                    Image(systemName: "leaf.fill")
                    Text("我的草")
                }
                .tag(0)
            
            MapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("地圖")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(2)
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
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo 區域
                VStack(spacing: 20) {
                    HandDrawnSproutView()
                        .frame(width: 120, height: 120)
                    
                    Text("種點什麼")
                        .font(.custom("PingFang TC", size: 32))
                        .fontWeight(.medium)
                        .foregroundColor(.brandDarkGray)
                    
                    Text("讓生活發芽")
                        .font(.custom("PingFang TC", size: 18))
                        .foregroundColor(.brandDarkGreen)
                        .padding(.top, -10)
                    
                    Text("每一步，都在種下你的回憶")
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGray.opacity(0.7))
                        .padding(.top, 5)
                }
                
                Spacer()
                
                // 登入按鈕
                VStack(spacing: 15) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                let userIdentifier = appleIDCredential.user
                                let fullName = appleIDCredential.fullName
                                let nickname = fullName?.givenName ?? fullName?.familyName ?? "新草"
                                let user = User(id: userIdentifier, nickname: nickname)
                                authManager.currentUser = user
                                authManager.isAuthenticated = true
                            }
                        case .failure(let error):
                            print("登入失敗: \(error.localizedDescription)")
                        }
                    }
                    .frame(height: 50)
                    .cornerRadius(12)
                    
                    Button(action: {
                        authManager.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("使用 Google 登入")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.brandDarkGray)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.brandGrayGreen, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
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
                .stroke(Color.brandLightGreen.opacity(0.3), lineWidth: 2)
                .frame(width: 100, height: 100)
            
            // 小芽
            Path { path in
                // 左葉
                path.move(to: CGPoint(x: 40, y: 60))
                path.addQuadCurve(to: CGPoint(x: 20, y: 40), control: CGPoint(x: 25, y: 50))
                path.addQuadCurve(to: CGPoint(x: 40, y: 60), control: CGPoint(x: 30, y: 50))
                
                // 右葉
                path.move(to: CGPoint(x: 60, y: 60))
                path.addQuadCurve(to: CGPoint(x: 80, y: 40), control: CGPoint(x: 75, y: 50))
                path.addQuadCurve(to: CGPoint(x: 60, y: 60), control: CGPoint(x: 70, y: 50))
                
                // 莖
                path.move(to: CGPoint(x: 50, y: 60))
                path.addQuadCurve(to: CGPoint(x: 50, y: 80), control: CGPoint(x: 45, y: 70))
            }
            .stroke(Color.brandDarkGreen, lineWidth: 3)
            .fill(Color.brandLightGreen)
        }
    }
}


#Preview {
    ContentView()
}
