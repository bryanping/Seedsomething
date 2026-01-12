//
//  FirestoreManager.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation
import FirebaseFirestore

/// Firestore 管理類（單例）
/// 注意：Firestore settings 必須在 AppDelegate 中配置，這裡只負責提供 Firestore 實例
final class FirestoreManager {
    static let shared = FirestoreManager()
    
    let db: Firestore
    
    private init() {
        // 直接使用 Firestore.firestore()，settings 已在 AppDelegate 中配置
        self.db = Firestore.firestore()
    }
}

