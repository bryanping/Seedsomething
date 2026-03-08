//
//  FirebaseService.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Firebase 數據服務類
/// 使用 FirestoreManager 獲取 Firestore 實例，不再自己配置 settings
class FirebaseService {
    static let shared = FirebaseService()

    private let db: Firestore

    private init() {
        // 使用 FirestoreManager 獲取已配置的 Firestore 實例
        // Firestore settings 已在 AppDelegate 中配置
        self.db = FirestoreManager.shared.db
    }

    // MARK: - Grass 数据

    func saveGrass(_ grass: Grass, userId: String) async throws {
        let data = try encode(grass)
        try await db.collection("users").document(userId).collection("data").document("grass")
            .setData(data)
    }

    func loadGrass(userId: String) async throws -> Grass? {
        let document = try await db.collection("users").document(userId).collection("data")
            .document("grass").getDocument()

        guard document.exists else {
            return nil
        }

        guard let data = document.data() else {
            return nil
        }

        return try decode(Grass.self, from: data)
    }

    // MARK: - PlantRecords 数据

    func savePlantRecords(_ records: [PlantRecord], userId: String) async throws {
        let batch = db.batch()
        let collectionRef = db.collection("users").document(userId).collection("plantRecords")

        // 删除所有现有记录
        let existingDocs = try await collectionRef.getDocuments()
        for doc in existingDocs.documents {
            batch.deleteDocument(doc.reference)
        }

        // 添加新记录
        for record in records {
            let data = try encode(record)
            let docRef = collectionRef.document(record.id)
            batch.setData(data, forDocument: docRef)
        }

        try await batch.commit()
    }

    func loadPlantRecords(userId: String) async throws -> [PlantRecord] {
        let snapshot =
            try await db
            .collection("users")
            .document(userId)
            .collection("plantRecords")
            .getDocuments()

        return snapshot.documents.compactMap { doc in  // 修改内容
            let data = doc.data()  // 修改内容
            return try? decode(PlantRecord.self, from: data)
        }
    }

    func addPlantRecord(_ record: PlantRecord, userId: String) async throws {
        let data = try encode(record)
        try await db.collection("users").document(userId).collection("plantRecords").document(
            record.id
        ).setData(data)
    }

    // MARK: - Stores 数据

    func saveStores(_ stores: [Store], userId: String) async throws {
        let batch = db.batch()
        let collectionRef = db.collection("users").document(userId).collection("stores")

        let existingDocs = try await collectionRef.getDocuments()
        for doc in existingDocs.documents {
            batch.deleteDocument(doc.reference)
        }

        for store in stores {
            let data = try encode(store)
            let docRef = collectionRef.document(store.id)
            batch.setData(data, forDocument: docRef)
        }

        try await batch.commit()
    }

    func loadStores(userId: String) async throws -> [Store] {
        let snapshot =
            try await db
            .collection("users")
            .document(userId)
            .collection("stores")
            .getDocuments()

        return snapshot.documents.compactMap { doc in  // 修改内容
            let data = doc.data()  // 修改内容
            return try? decode(Store.self, from: data)
        }
    }

    func addStore(_ store: Store, userId: String) async throws {
        let data = try encode(store)
        try await db.collection("users").document(userId).collection("stores").document(store.id)
            .setData(data)
    }

    // MARK: - Tasks 数据

    func saveTasks(_ tasks: [UserTask], userId: String) async throws {
        let batch = db.batch()
        let collectionRef = db.collection("users").document(userId).collection("tasks")

        let existingDocs = try await collectionRef.getDocuments()
        for doc in existingDocs.documents {
            batch.deleteDocument(doc.reference)
        }

        for task in tasks {
            let data = try encode(task)
            let docRef = collectionRef.document(task.id)
            batch.setData(data, forDocument: docRef)
        }

        try await batch.commit()
    }

    // MARK: - Tasks 数据

    func loadTasks(userId: String) async throws -> [UserTask] {
        let snapshot =
            try await db
            .collection("users")
            .document(userId)
            .collection("tasks")
            .getDocuments()

        // 修改內容：移除外层 try，doc.data() 不是 Optional
        return snapshot.documents.compactMap { doc in  // 修改內容
            let data = doc.data()  // 修改內容
            return try? decode(UserTask.self, from: data)
        }
    }

    // MARK: - Achievements 数据

    func saveAchievements(_ achievements: [Achievement], userId: String) async throws {
        let batch = db.batch()
        let collectionRef = db.collection("users").document(userId).collection("achievements")

        let existingDocs = try await collectionRef.getDocuments()
        for doc in existingDocs.documents {
            batch.deleteDocument(doc.reference)
        }

        for achievement in achievements {
            let data = try encode(achievement)
            let docRef = collectionRef.document(achievement.id)
            batch.setData(data, forDocument: docRef)
        }

        try await batch.commit()
    }

    // MARK: - Achievements 数据

    func loadAchievements(userId: String) async throws -> [Achievement] {
        let snapshot =
            try await db
            .collection("users")
            .document(userId)
            .collection("achievements")
            .getDocuments()

        // 修改內容：同上，移除外层 try，doc.data() 直接使用
        return snapshot.documents.compactMap { doc in  // 修改內容
            let data = doc.data()  // 修改內容
            return try? decode(Achievement.self, from: data)
        }
    }

    // MARK: - Friends 数据

    func saveFriends(_ friends: [Friend], userId: String) async throws {
        let batch = db.batch()
        let collectionRef = db.collection("users").document(userId).collection("friends")

        let existingDocs = try await collectionRef.getDocuments()
        for doc in existingDocs.documents {
            batch.deleteDocument(doc.reference)
        }

        for friend in friends {
            let data = try encode(friend)
            let docRef = collectionRef.document(friend.id)
            batch.setData(data, forDocument: docRef)
        }

        try await batch.commit()
    }

    func loadFriends(userId: String) async throws -> [Friend] {
        let snapshot =
            try await db
            .collection("users")
            .document(userId)
            .collection("friends")
            .getDocuments()

        return snapshot.documents.compactMap { doc in  // 修改内容
            let data = doc.data()  // 修改内容
            return try? decode(Friend.self, from: data)
        }
    }

    func addFriend(_ friend: Friend, userId: String) async throws {
        let data = try encode(friend)
        try await db.collection("users").document(userId).collection("friends").document(friend.id)
            .setData(data)
    }

    // MARK: - FriendInteractions 数据

    func saveFriendInteractions(_ interactions: [FriendInteraction], userId: String) async throws {
        let batch = db.batch()
        let collectionRef = db.collection("users").document(userId).collection("friendInteractions")

        let existingDocs = try await collectionRef.getDocuments()
        for doc in existingDocs.documents {
            batch.deleteDocument(doc.reference)
        }

        for interaction in interactions {
            let data = try encode(interaction)
            let docRef = collectionRef.document(interaction.id)
            batch.setData(data, forDocument: docRef)
        }

        try await batch.commit()
    }

    // MARK: - FriendInteractions 数据

    func loadFriendInteractions(userId: String) async throws -> [FriendInteraction] {
        let snapshot =
            try await db
            .collection("users")
            .document(userId)
            .collection("friendInteractions")
            .getDocuments()

        // 修改內容：與前兩個函式一致
        return snapshot.documents.compactMap { doc in  // 修改內容
            let data = doc.data()  // 修改內容
            return try? decode(FriendInteraction.self, from: data)
        }
    }

    func saveInteractionToBothUsers(
        interaction: FriendInteraction, currentUserId: String, friendId: String
    ) async throws {
        let batch = db.batch()
        let data = try encode(interaction)

        // 1. Save to Sender's collection (users/{me}/friendInteractions)
        let senderRef = db.collection("users").document(currentUserId).collection(
            "friendInteractions"
        ).document(interaction.id)
        batch.setData(data, forDocument: senderRef)

        // 2. Save to Receiver's collection (users/{friend}/friendInteractions)
        // Ensure we use the same collection name "friendInteractions"
        let receiverRef = db.collection("users").document(friendId).collection("friendInteractions")
            .document(interaction.id)
        batch.setData(data, forDocument: receiverRef)

        try await batch.commit()
    }

    func addFriendInteraction(_ interaction: FriendInteraction, userId: String) async throws {
        let data = try encode(interaction)
        try await db.collection("users").document(userId).collection("friendInteractions").document(
            interaction.id
        ).setData(data)
    }

    // MARK: - 工具方法

    // MARK: - 工具方法

    private func encode<T: Codable>(_ value: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let jsonData = try encoder.encode(value)

        // 修改內容：這裡的 jsonObject 是 throwing，要加 try
        let jsonObject = try JSONSerialization.jsonObject(  // 修改內容
            with: jsonData,
            options: []  // 修改內容（顯式 options）
        )

        guard let dictionary = jsonObject as? [String: Any] else {  // 修改內容
            throw NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "编码失败"]
            )
        }

        return dictionary
    }

    private func decode<T: Codable>(_ type: T.Type, from data: [String: Any]) throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(type, from: jsonData)
    }

    // MARK: - 公共打卡记录（所有用户可见）

    /// 添加公共打卡记录（存储到公共集合，所有用户可见）
    func addPublicPlantRecord(_ record: PlantRecord) async throws {
        // 确保用户已登录
        guard Auth.auth().currentUser != nil else {
            throw NSError(
                domain: "FirebaseService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "用户未登录，无法保存到公共集合"]
            )
        }

        let data = try encode(record)

        // 确保数据中包含 userId（用于权限验证）
        var recordData = data
        if recordData["userId"] == nil {
            recordData["userId"] = record.userId
        }

        // 存储到公共集合 publicPlantRecords
        do {
            try await db.collection("publicPlantRecords").document(record.id).setData(recordData)
        } catch let error as NSError {
            // 如果是权限错误，提供更详细的错误信息
            if error.domain == "FIRFirestoreErrorDomain" && error.code == 7 {
                throw NSError(
                    domain: "FirebaseService",
                    code: 403,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "权限不足：无法写入 publicPlantRecords 集合。请在 Firebase Console 中设置安全规则。",
                        NSLocalizedRecoverySuggestionErrorKey:
                            "请参考 FIREBASE_SECURITY_RULES.md 文件设置 Firestore 安全规则",
                    ]
                )
            }
            throw error
        }
    }

    /// 更新公共草点（浇水、访问、留言等增量更新）
    func updatePublicPlantRecord(_ record: PlantRecord) async throws {
        let data = try encode(record)
        try await db.collection("publicPlantRecords").document(record.id).setData(data, merge: true)
    }
    /// 注意：Firestore 不支持直接的地理位置查询，这里使用近似方法
    /// 实际生产环境建议使用 GeoFirestore 或类似的地理位置查询库
    func loadNearbyPlantRecords(
        center: CLLocationCoordinate2D, radiusKm: Double,
        completion: @escaping ([PlantRecord]) -> Void
    ) async throws {
        // 计算经纬度范围（近似）
        // 1度纬度 ≈ 111公里
        // 1度经度 ≈ 111 * cos(纬度) 公里
        let latDelta = radiusKm / 111.0
        let lonDelta = radiusKm / (111.0 * cos(center.latitude * .pi / 180.0))

        let minLat = center.latitude - latDelta
        let maxLat = center.latitude + latDelta
        let minLon = center.longitude - lonDelta
        let maxLon = center.longitude + lonDelta

        // 查询范围内的记录
        // 注意：Firestore 需要创建复合索引 (coordinate.latitude, coordinate.longitude)
        let snapshot = try await db.collection("publicPlantRecords")
            .whereField("coordinate.latitude", isGreaterThanOrEqualTo: minLat)
            .whereField("coordinate.latitude", isLessThanOrEqualTo: maxLat)
            .whereField("coordinate.longitude", isGreaterThanOrEqualTo: minLon)
            .whereField("coordinate.longitude", isLessThanOrEqualTo: maxLon)
            .limit(to: 1000)  // 限制最多1000条记录
            .getDocuments()

        var records: [PlantRecord] = []
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        for doc in snapshot.documents {
            let data = doc.data()
            if let record = try? decode(PlantRecord.self, from: data) {
                // 精确计算距离（过滤掉超出半径的记录）
                let recordLocation = CLLocation(
                    latitude: record.coordinate.latitude,
                    longitude: record.coordinate.longitude
                )
                let distance = centerLocation.distance(from: recordLocation) / 1000.0  // 转换为公里

                if distance <= radiusKm {
                    records.append(record)
                }
            }
        }

        completion(records)
    }
}
