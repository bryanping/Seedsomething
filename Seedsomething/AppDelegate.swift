//
//  AppDelegate.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 確保整個 App 生命週期只呼叫一次
        FirebaseApp.configure()
        
        // 若要客製 Firestore settings，只在這裡設定一次
        // 必须在 Firestore 实例被使用之前设置
        let settings = FirestoreSettings()
        // 启用离线持久化（可选）
        // settings.isPersistenceEnabled = true  // 视需求开启
        // 如果需要自定义缓存设置
        let cacheSize = NSNumber(value: 100 * 1024 * 1024) // 100MB
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: cacheSize)
        
        // 在 Firestore 被使用之前设置
        Firestore.firestore().settings = settings
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // 不需要特殊處理
    }
}
