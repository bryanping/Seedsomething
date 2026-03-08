//
//  PlantRecord.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation
import CoreLocation

enum PlantRecordType: String, Codable {
    case personalCheckin = "personal_checkin"
    case storeScan = "store_scan"
}

struct PlantRecord: Identifiable, Codable {
    let id: String
    let userId: String
    let type: PlantRecordType
    let coordinate: Coordinate
    let storeId: String?
    let createdAt: Date
    let grassLevel: Int? // 记录时的草等级（用于地图展示）

    /// 草点互动数据（地图上每个草点）
    var waterCount: Int
    var visitCount: Int
    var likeCount: Int
    var moodTag: String?
    var message: String?

    init(id: String = UUID().uuidString, userId: String, type: PlantRecordType, coordinate: Coordinate, storeId: String? = nil, createdAt: Date = Date(), grassLevel: Int? = nil, waterCount: Int = 0, visitCount: Int = 0, likeCount: Int = 0, moodTag: String? = nil, message: String? = nil) {
        self.id = id
        self.userId = userId
        self.type = type
        self.coordinate = coordinate
        self.storeId = storeId
        self.createdAt = createdAt
        self.grassLevel = grassLevel
        self.waterCount = waterCount
        self.visitCount = visitCount
        self.likeCount = likeCount
        self.moodTag = moodTag
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        userId = try c.decode(String.self, forKey: .userId)
        type = try c.decode(PlantRecordType.self, forKey: .type)
        coordinate = try c.decode(Coordinate.self, forKey: .coordinate)
        storeId = try c.decodeIfPresent(String.self, forKey: .storeId)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        grassLevel = try c.decodeIfPresent(Int.self, forKey: .grassLevel)
        waterCount = try c.decodeIfPresent(Int.self, forKey: .waterCount) ?? 0
        visitCount = try c.decodeIfPresent(Int.self, forKey: .visitCount) ?? 0
        likeCount = try c.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        moodTag = try c.decodeIfPresent(String.self, forKey: .moodTag)
        message = try c.decodeIfPresent(String.self, forKey: .message)
    }

    private enum CodingKeys: String, CodingKey {
        case id, userId, type, coordinate, storeId, createdAt, grassLevel
        case waterCount, visitCount, likeCount, moodTag, message
    }
}

// MARK: - 每日记录（浇水/任务完成写入当天，完整状态快照）
struct DailyPlantRecord: Codable, Equatable {
    /// 当天 0 点（用于按日去重）
    var date: Date
    var watered: Bool
    var tasksDone: [TaskType]
    var note: String?
    /// 心情快照（写入时的草状态）
    var mood: GrassMood?
    /// 当天是否获得/拥有露珠
    var dewEarned: Bool
    /// 当天累计获得的成长值（每次完成任务累加）
    var growthDelta: Int

    init(date: Date, watered: Bool = false, tasksDone: [TaskType] = [], note: String? = nil,
         mood: GrassMood? = nil, dewEarned: Bool = false, growthDelta: Int = 0) {
        self.date = Calendar.current.startOfDay(for: date)
        self.watered = watered
        self.tasksDone = tasksDone
        self.note = note
        self.mood = mood
        self.dewEarned = dewEarned
        self.growthDelta = growthDelta
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(Date.self, forKey: .date)
        watered = try c.decode(Bool.self, forKey: .watered)
        tasksDone = try c.decode([TaskType].self, forKey: .tasksDone)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        mood = try c.decodeIfPresent(GrassMood.self, forKey: .mood)
        dewEarned = try c.decodeIfPresent(Bool.self, forKey: .dewEarned) ?? false
        growthDelta = try c.decodeIfPresent(Int.self, forKey: .growthDelta) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case date, watered, tasksDone, note, mood, dewEarned, growthDelta
    }

    /// 日期键（yyyy-MM-dd）用于存储与查找
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        return formatter.string(from: Calendar.current.startOfDay(for: date))
    }
}

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(location: CLLocationCoordinate2D) {
        self.latitude = location.latitude
        self.longitude = location.longitude
    }
    
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

