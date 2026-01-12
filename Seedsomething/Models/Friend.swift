//
//  Friend.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation

struct Friend: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let friendUserId: String
    var friendNickname: String
    var friendAvatarUrl: String?
    let createdAt: Date
    var lastInteractionAt: Date?
    
    init(id: String = UUID().uuidString, userId: String, friendUserId: String, friendNickname: String, friendAvatarUrl: String? = nil, createdAt: Date = Date(), lastInteractionAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.friendUserId = friendUserId
        self.friendNickname = friendNickname
        self.friendAvatarUrl = friendAvatarUrl
        self.createdAt = createdAt
        self.lastInteractionAt = lastInteractionAt
    }
    
    static func == (lhs: Friend, rhs: Friend) -> Bool {
        return lhs.id == rhs.id && lhs.friendUserId == rhs.friendUserId
    }
}

enum FriendInteractionType: String, Codable {
    case like = "like"          // 点赞（原晒太阳）
    case sticker = "sticker"        // 留言小贴纸
    case viewFootprint = "view_footprint"  // 查看足迹
    
    var displayName: String {
        switch self {
        case .like: return "點讚"
        case .sticker: return "留言"
        case .viewFootprint: return "查看足迹"
        }
    }
}

struct FriendInteraction: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let type: FriendInteractionType
    var message: String?  // 贴纸留言
    let createdAt: Date
    
    init(id: String = UUID().uuidString, fromUserId: String, toUserId: String, type: FriendInteractionType, message: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.type = type
        self.message = message
        self.createdAt = createdAt
    }
}

struct FriendFootprint: Identifiable, Codable {
    let id: String
    let userId: String
    let friendUserId: String
    let storeId: String?
    let coordinate: Coordinate
    let createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, friendUserId: String, storeId: String?, coordinate: Coordinate, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.friendUserId = friendUserId
        self.storeId = storeId
        self.coordinate = coordinate
        self.createdAt = createdAt
    }
}

