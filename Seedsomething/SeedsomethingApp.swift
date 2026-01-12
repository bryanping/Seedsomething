//
//  SeedsomethingApp.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import FirebaseCore
import SwiftUI

@main
struct SeedsomethingApp: App {
    // 若需要 AppDelegate 處理推播、登入回調等，可以保留
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var authManager = AuthManager.shared
    @StateObject private var plantManager = PlantManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()  // 你的起始 View
                .environmentObject(authManager)
                .environmentObject(plantManager)
                .environmentObject(SettingsManager.shared)
                .onChange(of: authManager.isAuthenticated) { authenticated in
                    if authenticated {
                        Task {
                            await plantManager.loadData()
                        }
                    }
                }
                .task {
                    // 处理启动时已经是登录状态的情况
                    if authManager.isAuthenticated {
                        await plantManager.loadData()
                    }
                }
        }
    }
}

// RootView 就是原来的 ContentView
struct RootView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
    }
}
