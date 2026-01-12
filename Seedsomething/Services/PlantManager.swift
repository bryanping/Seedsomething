//
//  PlantManager.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import CoreLocation
import Foundation
import SwiftUI

/// 植物管理器
/// 使用 @MainActor 確保所有狀態更新在主線程
@MainActor
class PlantManager: NSObject, ObservableObject {
    static let shared = PlantManager()

    @Published var grass: Grass?
    @Published var plantRecords: [PlantRecord] = []  // 用户自己的记录
    @Published var allUsersPlantRecords: [PlantRecord] = []  // 所有用户的公共记录（用于地图显示）
    @Published var friendPlantRecords: [PlantRecord] = []  // 朋友的打卡记录（永远可见）
    @Published var stores: [Store] = []
    @Published var tasks: [UserTask] = []
    @Published var achievements: [Achievement] = []
    @Published var friends: [Friend] = []
    @Published var friendInteractions: [FriendInteraction] = []
    @Published var recentMutationMessage: String?

    @Published var currentLocation: CLLocationCoordinate2D?

    // 缓存已加载的区域，避免重复查询
    private var loadedRegions:
        [(center: CLLocationCoordinate2D, radius: Double, records: [PlantRecord])] = []
    private var lastLoadTime: Date?
    private var isLoadingNearbyRecords = false  // 防止并发加载

    // 每日种草次数限制
    private let dailyPlantLimit = 99

    // 使用统一的 LocationManager（不再自己管理 CLLocationManager）
    // 位置更新由 LocationManager 统一管理，通过 MapView 的 onChange 同步

    private override init() {
        super.init()
        // init 时不自动尝试加载，统一等待 AuthManager 状态变化通知或显式调用
    }

    // 更新当前位置（由外部调用，如 MapView）
    // @MainActor 確保在主線程更新
    func updateCurrentLocation(_ coordinate: CLLocationCoordinate2D) {
        currentLocation = coordinate
    }

    // 打卡（種草）- 浇水功能，不需要定位
    func checkIn() async throws {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw PlantError.notAuthenticated
        }

        // 檢查今天是否已打卡
        if let grass = grass, grass.hasCheckedInToday {
            throw PlantError.alreadyCheckedInToday
        }

        // 创建打卡记录（如果有位置就记录，没有位置就使用默认坐标）
        // 浇水功能不需要强制要求定位
        let coordinate: Coordinate
        if let location = LocationManager.shared.lastLocation?.coordinate {
            coordinate = Coordinate(location: location)
        } else {
            // 如果没有定位，使用默认坐标（不在地图上显示）
            coordinate = Coordinate(latitude: 0, longitude: 0)
        }

        let record = PlantRecord(
            userId: userId,
            type: .personalCheckin,
            coordinate: coordinate,
            grassLevel: grass?.level  // 记录当前等级
        )

        plantRecords.append(record)

        // 更新草資料
        if var currentGrass = grass {
            // 微小成長（基礎）
            currentGrass.addExp(1)
            currentGrass.lastCheckinAt = Date()
            currentGrass.totalCheckinCount += 1

            // 計算連續天數
            currentGrass.consecutiveDays = calculateConsecutiveDays()

            // 更新季節狀態
            currentGrass.updateForSeason(.current())

            // 檢查奇蹟觸發 (變異)
            if let mutation = calculateMutationTrigger(for: currentGrass) {
                currentGrass.mutationLevel = mutation.level
                currentGrass.mutationName = mutation.name
                self.recentMutationMessage = "Something feels different today."
                print("✨ 奇蹟發生了！植物變異為：\(mutation.name)")
            }

            self.grass = currentGrass
        } else {
            // 創建新的草
            var newGrass = Grass(userId: userId)
            newGrass.addExp(1)
            newGrass.lastCheckinAt = Date()
            newGrass.totalCheckinCount = 1
            newGrass.consecutiveDays = 1
            newGrass.updateForSeason(.current())
            self.grass = newGrass
        }

        // 檢查成就
        checkAchievements()

        Task {
            await saveData()
        }
    }

    // 随机种一颗种子
    func plantRandomSeed() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        // 只有当没有草的时候才能种植
        guard grass == nil else { return }

        // 随机选择一颗常见种子
        let species = PlantRandomizer.randomStarterSeed()

        // 创建新的草
        let newGrass = Grass(
            userId: userId,
            plantSpecies: species
        )
        // 初始不做任何成长，等待用户浇水

        self.grass = newGrass

        Task {
            await saveData()
        }
    }

    // 在GPS定位位置种草（地图种草，每日可99次）
    func plantAtLocation(_ location: CLLocationCoordinate2D) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw PlantError.notAuthenticated
        }

        // 檢查今日已種草次數
        let todayPlantCount = getTodayPlantCount()
        if todayPlantCount >= dailyPlantLimit {
            throw PlantError.dailyLimitReached
        }

        // 創建打卡記錄（必須有有效經緯度）
        let record = PlantRecord(
            userId: userId,
            type: .personalCheckin,
            coordinate: Coordinate(location: location),
            grassLevel: grass?.level  // 记录当前等级
        )

        plantRecords.append(record)

        // 同時保存到公共集合（所有用戶可見）
        // 如果权限不足，至少保存到本地，不阻止种草操作
        do {
            try await FirebaseService.shared.addPublicPlantRecord(record)
        } catch {
            // 权限错误时，记录日志但不阻止操作
            // 用户数据已保存到本地，可以在权限修复后同步
            print("⚠️ 保存到公共集合失败（可能是权限问题）: \(error.localizedDescription)")
            print("💡 提示：请在 Firebase Console 中设置 publicPlantRecords 集合的写入权限")
            // 不抛出错误，允许继续执行
        }

        // 更新草資料（只有第一次打卡才更新 lastCheckinAt）
        if var currentGrass = grass {
            // 微小成長（基礎）
            currentGrass.addExp(1)

            // 只有第一次打卡才更新 lastCheckinAt
            if !currentGrass.hasCheckedInToday {
                currentGrass.lastCheckinAt = Date()
                // 計算連續天數
                currentGrass.consecutiveDays = calculateConsecutiveDays()
            }

            currentGrass.totalCheckinCount += 1

            // 更新季節狀態
            currentGrass.updateForSeason(Season.current())

            self.grass = currentGrass
        } else {
            // 創建新的草
            var newGrass = Grass(userId: userId)
            newGrass.addExp(1)
            newGrass.lastCheckinAt = Date()
            newGrass.totalCheckinCount = 1
            newGrass.consecutiveDays = 1
            newGrass.updateForSeason(Season.current())
            self.grass = newGrass
        }

        // 檢查成就
        checkAchievements()

        Task {
            await saveData()
        }
    }

    // 獲取今日已種草次數
    private func getTodayPlantCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return plantRecords.filter { record in
            record.createdAt >= today
        }.count
    }

    // 检查是否已加载过该区域的数据
    private func hasLoadedRegion(center: CLLocationCoordinate2D, radius: Double) -> Bool {
        let threshold = 0.5  // 0.5公里内的区域视为相同
        return loadedRegions.contains { cached in
            let distance =
                CLLocation(latitude: center.latitude, longitude: center.longitude)
                .distance(
                    from: CLLocation(
                        latitude: cached.center.latitude, longitude: cached.center.longitude))
                / 1000.0
            return distance < threshold && abs(cached.radius - radius) < 0.5
        }
    }

    // 加載指定位置附近的所有用戶打卡記錄（优化版：防抖、去重、缓存）
    func loadNearbyPlantRecords(center: CLLocationCoordinate2D, initialRadiusKm: Double = 3.0)
        async throws
    {
        // 防止并发加载
        guard !isLoadingNearbyRecords else {
            print("⏸️ 已有加载任务进行中，跳过此次请求")
            return
        }

        // 防抖：如果距离上次加载时间少于2秒，跳过
        if let lastLoad = lastLoadTime, Date().timeIntervalSince(lastLoad) < 2.0 {
            print("⏸️ 距离上次加载时间过短，跳过此次请求")
            return
        }

        // 检查缓存：如果已加载过该区域，直接返回缓存数据
        if hasLoadedRegion(center: center, radius: initialRadiusKm) {
            if let cached = loadedRegions.first(where: { cached in
                let distance =
                    CLLocation(latitude: center.latitude, longitude: center.longitude)
                    .distance(
                        from: CLLocation(
                            latitude: cached.center.latitude, longitude: cached.center.longitude))
                    / 1000.0
                return distance < 0.5 && abs(cached.radius - initialRadiusKm) < 0.5
            }) {
                await MainActor.run {
                    self.allUsersPlantRecords = cached.records
                }
                print("✅ 使用缓存数据，共 \(cached.records.count) 条记录")
                return
            }
        }

        isLoadingNearbyRecords = true
        lastLoadTime = Date()

        defer {
            isLoadingNearbyRecords = false
        }

        var currentRadius = initialRadiusKm
        var allRecords: Set<String> = []  // 使用 Set 去重（基于 record.id）
        var uniqueRecords: [PlantRecord] = []

        // 先嘗試3公里範圍
        do {
            var fetchedRecords: [PlantRecord] = []
            try await FirebaseService.shared.loadNearbyPlantRecords(
                center: center, radiusKm: currentRadius
            ) { records in
                fetchedRecords = records
            }

            // 去重：只添加新的记录
            for record in fetchedRecords {
                if !allRecords.contains(record.id) {
                    allRecords.insert(record.id)
                    uniqueRecords.append(record)
                }
            }

            print("📍 在 \(currentRadius)km 范围内找到 \(uniqueRecords.count) 条新记录（去重后）")
        } catch {
            print("⚠️ 加载附近记录失败: \(error.localizedDescription)")
            // 如果是索引错误，不抛出异常，返回空数组
            if error.localizedDescription.contains("index")
                || error.localizedDescription.contains("indexes")
            {
                print("💡 提示：需要在 Firebase Console 中创建复合索引，请参考 FIREBASE_INDEX_SETUP.md")
                await MainActor.run { self.allUsersPlantRecords = [] }
                return
            }
            throw error
        }

        // 如果記錄少於10個，逐步擴大範圍（最多擴大到10公里）
        // 优化：只查询新增的环形区域，而不是整个范围
        while uniqueRecords.count < 10 && currentRadius < 10.0 {
            let previousRadius = currentRadius
            currentRadius += 2.0  // 每次增加2公里

            do {
                // 查询整个新范围
                var fetchedRecords: [PlantRecord] = []
                try await FirebaseService.shared.loadNearbyPlantRecords(
                    center: center, radiusKm: currentRadius
                ) { records in
                    fetchedRecords = records
                }

                // 只添加新记录（去重）
                var newCount = 0
                for record in fetchedRecords {
                    if !allRecords.contains(record.id) {
                        allRecords.insert(record.id)
                        uniqueRecords.append(record)
                        newCount += 1
                    }
                }

                print("📍 扩大到 \(currentRadius)km 范围，新增 \(newCount) 条记录，总计 \(uniqueRecords.count) 条")
            } catch {
                print("⚠️ 扩大范围查询失败: \(error.localizedDescription)")
                break
            }

            // 如果已經擴大到10公里，停止擴大
            if currentRadius >= 10.0 {
                break
            }
        }

        // 更新缓存
        loadedRegions.append((center: center, radius: currentRadius, records: uniqueRecords))
        // 限制缓存数量，只保留最近5个区域
        if loadedRegions.count > 5 {
            loadedRegions.removeFirst()
        }

        // 更新到主線程
        await MainActor.run {
            self.allUsersPlantRecords = uniqueRecords
            print("✅ 最终加载了 \(uniqueRecords.count) 条打卡记录到地图（已去重）")
        }
    }

    // 加載朋友的打卡記錄（永遠可見，緩存到本地）
    func loadFriendPlantRecords() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        // 先從本地緩存加載
        if let cachedData = UserDefaults.standard.data(forKey: "friendPlantRecords") {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            if let cachedRecords = try? decoder.decode([PlantRecord].self, from: cachedData) {
                await MainActor.run {
                    self.friendPlantRecords = cachedRecords
                }
            }
        }

        // 從 Firebase 加載所有朋友的打卡記錄
        var allFriendRecords: [PlantRecord] = []

        for friend in friends {
            do {
                // 加載每個朋友的打卡記錄
                let friendRecords = try await FirebaseService.shared.loadPlantRecords(
                    userId: friend.friendUserId)
                allFriendRecords.append(contentsOf: friendRecords)
            } catch {
                print("加載朋友 \(friend.friendNickname) 的打卡記錄失敗: \(error.localizedDescription)")
            }
        }

        // 更新到主線程並緩存到本地
        await MainActor.run {
            self.friendPlantRecords = allFriendRecords

            // 保存到本地緩存
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            if let encoded = try? encoder.encode(allFriendRecords) {
                UserDefaults.standard.set(encoded, forKey: "friendPlantRecords")
            }
        }
    }

    // 掃碼種草
    func scanAndPlant(storeId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw PlantError.notAuthenticated
        }

        guard stores.first(where: { $0.id == storeId }) != nil else {
            throw PlantError.storeNotFound
        }

        // 使用 LocationManager 获取位置
        guard let location = LocationManager.shared.lastLocation?.coordinate else {
            throw PlantError.locationNotAvailable
        }

        // 創建店家掃碼記錄
        let record = PlantRecord(
            userId: userId,
            type: .storeScan,
            coordinate: Coordinate(location: location),
            storeId: storeId
        )

        plantRecords.append(record)

        // 更新草資料
        if var currentGrass = grass {
            currentGrass.addExp(15)  // 店家掃碼經驗值更高
            self.grass = currentGrass
        } else {
            var newGrass = Grass(userId: userId)
            newGrass.addExp(15)
            self.grass = newGrass
        }

        // 更新店家種草數
        if let index = stores.firstIndex(where: { $0.id == storeId }) {
            stores[index].totalPlantCount += 1
        }

        Task {
            await saveData()
        }
    }

    // 創建店家花園
    func createStore(name: String, coordinate: Coordinate) async throws -> Store {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw PlantError.notAuthenticated
        }

        let store = Store(
            ownerUserId: userId,
            name: name,
            coordinate: coordinate
        )

        stores.append(store)
        await saveData()

        return store
    }

    // 根據 QR Token 查找店家
    func findStoreByQRToken(_ token: String) -> Store? {
        return stores.first { $0.qrCodeToken == token }
    }

    private func saveData() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        do {
            // 1. 保存所有数据到 Firebase
            if let grass = grass {
                try await FirebaseService.shared.saveGrass(grass, userId: userId)
            }
            try await FirebaseService.shared.savePlantRecords(plantRecords, userId: userId)
            try await FirebaseService.shared.saveStores(stores, userId: userId)
            try await FirebaseService.shared.saveTasks(tasks, userId: userId)
            try await FirebaseService.shared.saveAchievements(achievements, userId: userId)
            try await FirebaseService.shared.saveFriends(friends, userId: userId)
            try await FirebaseService.shared.saveFriendInteractions(
                friendInteractions, userId: userId)

            // 2. 同时保存到 UserDefaults 作为本地缓存 (防止网络失败时丢失进度)
            saveToLocalCache()

        } catch {
            print("保存数据到 Firebase 失敗: \(error.localizedDescription)")
            // 即使网络失败，也要保存到本地
            saveToLocalCache()
        }
    }

    // 保存数据到本地缓存
    private func saveToLocalCache() {
        if let grass = grass, let encoded = try? JSONEncoder().encode(grass) {
            UserDefaults.standard.set(encoded, forKey: "grass")
        }
        if let encoded = try? JSONEncoder().encode(plantRecords) {
            UserDefaults.standard.set(encoded, forKey: "plantRecords")
        }
        if let encoded = try? JSONEncoder().encode(stores) {
            UserDefaults.standard.set(encoded, forKey: "stores")
        }
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
        if let encoded = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(encoded, forKey: "friends")
        }
    }

    // 計算連續打卡天數
    private func calculateConsecutiveDays() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 找出所有打打卡日期并排序
        let checkinDates = Set(plantRecords.map { calendar.startOfDay(for: $0.createdAt) })
        let sortedDates = checkinDates.sorted(by: >)

        guard let latest = sortedDates.first else { return 0 }

        // 如果最后一次打卡不是今天也不是昨天，说明断了
        if !calendar.isDate(latest, inSameDayAs: today)
            && !calendar.isDate(
                latest, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!)
        {
            return 0
        }

        var count = 0
        var currentDate = latest

        while checkinDates.contains(currentDate) {
            count += 1
            guard let nextDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return count
    }

    // 完成任務
    func completeTask(_ task: UserTask) {
        guard AuthManager.shared.currentUser?.id != nil else { return }

        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            updatedTask.complete()
            tasks[index] = updatedTask

            // 給予微小成長值
            if var currentGrass = grass {
                currentGrass.addExp(task.type.expReward)
                self.grass = currentGrass
            }

            Task {
                await saveData()
            }
        }
    }

    // 檢查成就（支持LV等级系统）
    private func checkAchievements() {
        guard let userId = AuthManager.shared.currentUser?.id,
            let currentGrass = grass
        else { return }

        // 初始化成就列表（如果為空）
        if achievements.isEmpty {
            achievements = [
                Achievement(
                    userId: userId, type: .consecutive7Days,
                    target: Achievement.getTarget(for: .consecutive7Days, level: 1)),
                Achievement(
                    userId: userId, type: .consecutive30Days,
                    target: Achievement.getTarget(for: .consecutive30Days, level: 1)),
                Achievement(
                    userId: userId, type: .summerGrowth,
                    target: Achievement.getTarget(for: .summerGrowth, level: 1)),
                Achievement(
                    userId: userId, type: .firstFriend,
                    target: Achievement.getTarget(for: .firstFriend, level: 1)),
                Achievement(
                    userId: userId, type: .friendLike,
                    target: Achievement.getTarget(for: .friendLike, level: 1)),
                Achievement(
                    userId: userId, type: .storePlant,
                    target: Achievement.getTarget(for: .storePlant, level: 1)),
                Achievement(
                    userId: userId, type: .totalCheckins,
                    target: Achievement.getTarget(for: .totalCheckins, level: 1)),
            ]
        }

        // 更新成就进度并检查升级
        for index in achievements.indices {
            var achievement = achievements[index]
            var shouldUpdate = false

            switch achievement.type {
            case .consecutive7Days, .consecutive30Days:
                achievement.progress = currentGrass.consecutiveDays

            case .summerGrowth:
                achievement.progress = currentGrass.exp

            case .firstFriend:
                achievement.progress = friends.count

            case .friendLike:
                achievement.progress = friendInteractions.filter { $0.type == .like }.count

            case .storePlant:
                let uniqueStores = Set(
                    plantRecords.filter { $0.type == .storeScan }.compactMap { $0.storeId })
                achievement.progress = uniqueStores.count

            case .totalCheckins:
                achievement.progress = currentGrass.totalCheckinCount
            }

            // 统一的解锁和升级逻辑
            if achievement.progress >= achievement.target && !achievement.isUnlocked {
                achievement.unlock()
                shouldUpdate = true
            } else if achievement.isUnlocked
                && achievement.level < Achievement.maxLevel(for: achievement.type)
            {
                let nextLevelTarget = Achievement.getTarget(
                    for: achievement.type, level: achievement.level + 1)
                if achievement.progress >= nextLevelTarget {
                    achievement.level += 1
                    achievement.target = nextLevelTarget
                    achievement.isUnlocked = false  // 为新等级重新锁定
                    shouldUpdate = true
                }
            }

            if shouldUpdate {
                achievements[index] = achievement
            }
        }
    }

    // 后台自动检测日常任务（隐藏功能，完成时自动加成长值）
    func checkDailyTasks() {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        // 初始化任务列表（如果为空）
        if tasks.isEmpty {
            tasks = TaskType.allCases.filter { $0 != .custom }.map { type in
                UserTask(userId: userId, type: type)
            }
        }

        // 检查每个任务是否完成（这里简化处理，实际应该根据具体任务类型检测）
        // 例如：运动、阅读等需要用户主动标记，但我们可以检测浇水任务
        for index in tasks.indices {
            var task = tasks[index]

            // 浇水任务：如果今天已打卡，自动完成
            if task.type == .water {
                if let currentGrass = grass, currentGrass.hasCheckedInToday, !task.isCompletedToday
                {
                    task.complete()
                    tasks[index] = task

                    // 给予成长值
                    var updatedGrass = currentGrass
                    updatedGrass.addExp(task.type.expReward)
                    self.grass = updatedGrass
                }
            }
            // 其他任务需要用户主动完成，这里不做自动检测
        }

        Task {
            await saveData()
        }
    }

    // MARK: - Social Features (Firestore)

    // 搜索用户
    func searchUser(by id: String) async throws -> User? {
        let doc = try await FirestoreManager.shared.db.collection("users").document(id)
            .getDocument()
        if doc.exists {
            return try? doc.data(as: User.self)
        }
        return nil
    }

    // 添加好友
    func addFriend(_ friend: Friend) {
        // 防止重复添加
        guard !friends.contains(where: { $0.friendUserId == friend.friendUserId }) else { return }

        friends.append(friend)

        // 保存到 Firestore
        Task {
            do {
                if let currentUserId = AuthManager.shared.currentUser?.id {
                    let friendRef = FirestoreManager.shared.db.collection("users").document(
                        currentUserId
                    ).collection("friends").document(friend.friendUserId)
                    try friendRef.setData(from: friend)

                    // 重新加载好友打卡记录
                    await loadFriendPlantRecords()
                }
            } catch {
                print("保存好友失败: \(error)")
            }
        }
    }

    // 发送点赞 (互动)
    func interactWithFriend(friendId: String, type: FriendInteractionType) async throws {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return }

        // 1. 创建互动记录
        let interaction = FriendInteraction(
            fromUserId: currentUserId,
            toUserId: friendId,
            type: type
        )
        // 留言贴纸逻辑后续扩展...

        // 2. 双写互动记录到双方的集合
        try await FirebaseService.shared.saveInteractionToBothUsers(
            interaction: interaction,
            currentUserId: currentUserId,
            friendId: friendId
        )

        // 3. 更新本地好友状态 (lastInteractionAt)
        if let index = friends.firstIndex(where: { $0.friendUserId == friendId }) {
            var updatedFriend = friends[index]
            updatedFriend.lastInteractionAt = Date()
            friends[index] = updatedFriend

            // 更新 Firestore 中的好友状态
            let myFriendRef = FirestoreManager.shared.db.collection("users").document(currentUserId)
                .collection("friends").document(friendId)
            try await myFriendRef.updateData(["lastInteractionAt": Date()])
        }

        // 4. Update local interaction list for immediate UI feedback
        // This ensures checkLikeStatus in FriendGardenView finds the new interaction
        await MainActor.run {
            self.friendInteractions.append(interaction)
        }

        // 5. 检查互动成就
        if type == .like {
            // 简单计数，实际应该从服务器获取准确计数
            let likeCount = friendInteractions.filter({ $0.type == .like }).count  // +1 is already added to list above
            if likeCount >= 2 {
                // 解锁成就逻辑 (简化)
                if let index = achievements.firstIndex(where: {
                    $0.type == .friendLike && !$0.isUnlocked
                }) {
                    achievements[index].unlock()
                }
            }
        }
    }

    // 兼容旧方法调用，转发到新方法
    func sendLike(to friendId: String) {
        Task {
            try? await interactWithFriend(friendId: friendId, type: .like)
        }
    }

    // 加载好友列表
    private func loadFriends() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        do {
            let snapshot = try await FirestoreManager.shared.db.collection("users").document(userId)
                .collection("friends").getDocuments()
            let loadedFriends = snapshot.documents.compactMap { try? $0.data(as: Friend.self) }

            await MainActor.run {
                self.friends = loadedFriends
            }
        } catch {
            print("加载好友失败: \(error)")
        }
    }

    func loadData() async {
        guard let userId = AuthManager.shared.currentUser?.id else {
            // 如果用户未登录，尝试从 UserDefaults 迁移数据
            await migrateFromUserDefaults()
            return
        }

        do {
            // 从 Firebase 加载所有数据
            grass = try await FirebaseService.shared.loadGrass(userId: userId)
            plantRecords = try await FirebaseService.shared.loadPlantRecords(userId: userId)
            stores = try await FirebaseService.shared.loadStores(userId: userId)
            tasks = try await FirebaseService.shared.loadTasks(userId: userId)
            achievements = try await FirebaseService.shared.loadAchievements(userId: userId)
            friends = try await FirebaseService.shared.loadFriends(userId: userId)
            friendInteractions = try await FirebaseService.shared.loadFriendInteractions(
                userId: userId)

            // 如果 Firebase 没有数据，尝试从 UserDefaults 迁移
            if grass == nil && plantRecords.isEmpty {
                await migrateFromUserDefaults()
            }
        } catch {
            print("从 Firebase 加载数据失败: \(error.localizedDescription)")
            // 如果 Firebase 加载失败，尝试从 UserDefaults 加载
            await migrateFromUserDefaults()
        }
    }

    // 从 UserDefaults 迁移数据到 Firebase
    private func migrateFromUserDefaults() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        // 从 UserDefaults 加载数据
        if let data = UserDefaults.standard.data(forKey: "grass"),
            let decoded = try? JSONDecoder().decode(Grass.self, from: data)
        {
            grass = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "plantRecords"),
            let decoded = try? JSONDecoder().decode([PlantRecord].self, from: data)
        {
            plantRecords = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "stores"),
            let decoded = try? JSONDecoder().decode([Store].self, from: data)
        {
            stores = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "tasks"),
            let decoded = try? JSONDecoder().decode([UserTask].self, from: data)
        {
            tasks = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "achievements"),
            let decoded = try? JSONDecoder().decode([Achievement].self, from: data)
        {
            achievements = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "friends"),
            let decoded = try? JSONDecoder().decode([Friend].self, from: data)
        {
            friends = decoded
        }

        // 如果有数据，保存到 Firebase
        if grass != nil || !plantRecords.isEmpty {
            await saveData()

            // 迁移完成后，清除 UserDefaults（可选）
            // UserDefaults.standard.removeObject(forKey: "grass")
            // UserDefaults.standard.removeObject(forKey: "plantRecords")
            // ...
        }
    }

    // MARK: - Mutation Logic (Miracle Trigger)

    /// 计算奇迹触发（变异系统）
    /// - Returns: 变异等级和名称 (如果触发)
    private func calculateMutationTrigger(for currentGrass: Grass) -> (level: Int, name: String)? {
        // 如果已经达到顶级变异，不再触发
        if currentGrass.mutationLevel >= 4 { return nil }

        // 第一层：基础概率 (Natural Probability)
        let baseLv1 = 0.0002  // 0.02%
        let baseLv2 = 0.0001
        let baseLv3 = 0.00005
        let baseLv4 = 0.00001

        // 第二层：行为加成 (Behavior Multipliers - Multiplicative)
        var multiplier: Double = 1.0

        // 连续登录加成
        if currentGrass.consecutiveDays >= 7 {
            multiplier *= 1.25
        } else if currentGrass.consecutiveDays >= 3 {
            multiplier *= 1.10
        }

        // 当天任务加成 (检查是否有任务已完成)
        if tasks.contains(where: { $0.isCompletedToday }) {
            multiplier *= 1.10
        }

        // 无催促登录 (这里由于逻辑简化，暂定为如果今天打过卡了就算有此心境)
        // 实际应该是检测是否从通知点进来的
        multiplier *= 1.05

        // 情绪彩蛋：深夜或清晨 (11PM - 5AM)
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 23 || hour <= 5 {
            multiplier *= 1.05
        }

        // 第三层：阶段权重 (Stage Weight)
        // 预留 Stage 5, 8, 10 的权重 (目前维持 1.0)

        let finalProbLv1 = baseLv1 * multiplier
        let finalProbLv2 = baseLv2 * multiplier
        let finalProbLv3 = baseLv3 * multiplier
        let finalProbLv4 = baseLv4 * multiplier

        let roll = Double.random(in: 0...1)

        var triggeredLevel: Int = 0
        if roll < finalProbLv4 {
            triggeredLevel = 4
        } else if roll < finalProbLv3 {
            triggeredLevel = 3
        } else if roll < finalProbLv2 {
            triggeredLevel = 2
        } else if roll < finalProbLv1 {
            triggeredLevel = 1
        }

        if triggeredLevel > currentGrass.mutationLevel {
            let name = currentGrass.plantSpecies?.mutationName(for: triggeredLevel) ?? "稀有植物"
            return (triggeredLevel, name)
        }

        return nil
    }
}

// 注意：PlantManager 不再需要实现 CLLocationManagerDelegate
// 定位功能已统一由 LocationManager 管理
// 位置更新通过 updateCurrentLocation() 方法同步

enum PlantError: LocalizedError {
    case notAuthenticated
    case locationNotAvailable
    case alreadyCheckedInToday
    case storeNotFound
    case dailyLimitReached

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "請先登入"
        case .locationNotAvailable:
            return "無法取得位置資訊"
        case .alreadyCheckedInToday:
            return "今日已打卡"
        case .storeNotFound:
            return "找不到店家"
        case .dailyLimitReached:
            return "今日已達99次種草上限"
        }
    }
}
