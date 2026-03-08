//
//  LocalStore.swift
//  Seedsomething
//
//  本地持久化层：UserDefaults + Codable，App 启动加载，修改即保存。
//

import Foundation

/// 本地存储：所有状态可持久化，重启 App 数据不丢。
final class LocalStore {
    static let shared = LocalStore()
    private let defaults = UserDefaults.standard
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private enum Keys {
        static let grass = "localStore.grass"
        static let plantRecords = "localStore.plantRecords"
        static let dailyPlantRecords = "localStore.dailyPlantRecords"
        static let stores = "localStore.stores"
        static let tasks = "localStore.tasks"
        static let achievements = "localStore.achievements"
        static let friends = "localStore.friends"
        static let friendInteractions = "localStore.friendInteractions"
    }

    private init() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .secondsSince1970
        encoder = enc
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .secondsSince1970
        decoder = dec
    }

    // MARK: - 按 userId 命名空间（单用户时可用默认 key，多用户时可加 userId 后缀）
    private func key(_ base: String, userId: String?) -> String {
        guard let uid = userId, !uid.isEmpty else { return base }
        return "\(base).\(uid)"
    }

    // MARK: - Grass
    func loadGrass(userId: String?) -> Grass? {
        guard let data = defaults.data(forKey: key(Keys.grass, userId: userId)) else { return nil }
        return try? decoder.decode(Grass.self, from: data)
    }

    func saveGrass(_ grass: Grass?, userId: String?) {
        let k = key(Keys.grass, userId: userId)
        if let g = grass, let data = try? encoder.encode(g) {
            defaults.set(data, forKey: k)
        } else {
            defaults.removeObject(forKey: k)
        }
    }

    // MARK: - PlantRecords（地图打卡记录）
    func loadPlantRecords(userId: String?) -> [PlantRecord] {
        guard let data = defaults.data(forKey: key(Keys.plantRecords, userId: userId)) else { return [] }
        return (try? decoder.decode([PlantRecord].self, from: data)) ?? []
    }

    func savePlantRecords(_ records: [PlantRecord], userId: String?) {
        let k = key(Keys.plantRecords, userId: userId)
        guard let data = try? encoder.encode(records) else { return }
        defaults.set(data, forKey: k)
    }

    // MARK: - DailyPlantRecord（每日记录：按日期读写）
    /// 按日期读取当日记录
    func dailyRecord(for date: Date, userId: String?) -> DailyPlantRecord? {
        let all = loadDailyPlantRecords(userId: userId)
        let key = DailyPlantRecord.dateKey(for: date)
        return all[key]
    }

    /// 写入或更新当日记录
    func saveDailyRecord(_ record: DailyPlantRecord, userId: String?) {
        var all = loadDailyPlantRecords(userId: userId)
        let key = DailyPlantRecord.dateKey(for: record.date)
        all[key] = record
        saveDailyPlantRecords(all, userId: userId)
    }

    /// 今天是否已浇水（仅看每日记录；与 Grass.hasCheckedInToday 可二选一或同时用）
    func hasWateredToday(userId: String?) -> Bool {
        dailyRecord(for: Date(), userId: userId)?.watered ?? false
    }

    private func loadDailyPlantRecords(userId: String?) -> [String: DailyPlantRecord] {
        guard let data = defaults.data(forKey: key(Keys.dailyPlantRecords, userId: userId)) else { return [:] }
        return (try? decoder.decode([String: DailyPlantRecord].self, from: data)) ?? [:]
    }

    private func saveDailyPlantRecords(_ records: [String: DailyPlantRecord], userId: String?) {
        let k = key(Keys.dailyPlantRecords, userId: userId)
        guard let data = try? encoder.encode(records) else { return }
        defaults.set(data, forKey: k)
    }

    // MARK: - Stores / Tasks / Achievements / Friends / FriendInteractions
    func loadStores(userId: String?) -> [Store] {
        guard let data = defaults.data(forKey: key(Keys.stores, userId: userId)) else { return [] }
        return (try? decoder.decode([Store].self, from: data)) ?? []
    }

    func saveStores(_ stores: [Store], userId: String?) {
        let k = key(Keys.stores, userId: userId)
        guard let data = try? encoder.encode(stores) else { return }
        defaults.set(data, forKey: k)
    }

    func loadTasks(userId: String?) -> [UserTask] {
        guard let data = defaults.data(forKey: key(Keys.tasks, userId: userId)) else { return [] }
        return (try? decoder.decode([UserTask].self, from: data)) ?? []
    }

    func saveTasks(_ tasks: [UserTask], userId: String?) {
        let k = key(Keys.tasks, userId: userId)
        guard let data = try? encoder.encode(tasks) else { return }
        defaults.set(data, forKey: k)
    }

    func loadAchievements(userId: String?) -> [Achievement] {
        guard let data = defaults.data(forKey: key(Keys.achievements, userId: userId)) else { return [] }
        return (try? decoder.decode([Achievement].self, from: data)) ?? []
    }

    func saveAchievements(_ achievements: [Achievement], userId: String?) {
        let k = key(Keys.achievements, userId: userId)
        guard let data = try? encoder.encode(achievements) else { return }
        defaults.set(data, forKey: k)
    }

    func loadFriends(userId: String?) -> [Friend] {
        guard let data = defaults.data(forKey: key(Keys.friends, userId: userId)) else { return [] }
        return (try? decoder.decode([Friend].self, from: data)) ?? []
    }

    func saveFriends(_ friends: [Friend], userId: String?) {
        let k = key(Keys.friends, userId: userId)
        guard let data = try? encoder.encode(friends) else { return }
        defaults.set(data, forKey: k)
    }

    func loadFriendInteractions(userId: String?) -> [FriendInteraction] {
        guard let data = defaults.data(forKey: key(Keys.friendInteractions, userId: userId)) else { return [] }
        return (try? decoder.decode([FriendInteraction].self, from: data)) ?? []
    }

    func saveFriendInteractions(_ list: [FriendInteraction], userId: String?) {
        let k = key(Keys.friendInteractions, userId: userId)
        guard let data = try? encoder.encode(list) else { return }
        defaults.set(data, forKey: k)
    }

    // MARK: - 一次性加载所有本地数据（用于启动）
    struct LoadedData {
        var grass: Grass?
        var plantRecords: [PlantRecord]
        var dailyPlantRecords: [String: DailyPlantRecord]
        var stores: [Store]
        var tasks: [UserTask]
        var achievements: [Achievement]
        var friends: [Friend]
        var friendInteractions: [FriendInteraction]
    }

    func loadAll(userId: String?) -> LoadedData {
        LoadedData(
            grass: loadGrass(userId: userId),
            plantRecords: loadPlantRecords(userId: userId),
            dailyPlantRecords: loadDailyPlantRecords(userId: userId),
            stores: loadStores(userId: userId),
            tasks: loadTasks(userId: userId),
            achievements: loadAchievements(userId: userId),
            friends: loadFriends(userId: userId),
            friendInteractions: loadFriendInteractions(userId: userId)
        )
    }

    /// 保存当前 PlantManager 状态（调用方传入，便于一处写入）
    func saveAll(
        grass: Grass?,
        plantRecords: [PlantRecord],
        dailyPlantRecords: [String: DailyPlantRecord],
        stores: [Store],
        tasks: [UserTask],
        achievements: [Achievement],
        friends: [Friend],
        friendInteractions: [FriendInteraction],
        userId: String?
    ) {
        saveGrass(grass, userId: userId)
        savePlantRecords(plantRecords, userId: userId)
        saveDailyPlantRecords(dailyPlantRecords, userId: userId)
        saveStores(stores, userId: userId)
        saveTasks(tasks, userId: userId)
        saveAchievements(achievements, userId: userId)
        saveFriends(friends, userId: userId)
        saveFriendInteractions(friendInteractions, userId: userId)
    }
}
