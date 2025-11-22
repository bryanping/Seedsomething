//
//  User.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    var nickname: String
    var avatarUrl: String?
    let createdAt: Date
    
    init(id: String = UUID().uuidString, nickname: String, avatarUrl: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.nickname = nickname
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
    }
}

