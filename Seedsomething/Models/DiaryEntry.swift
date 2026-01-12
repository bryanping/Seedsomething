//
//  DiaryEntry.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import Foundation

/// 日記條目
struct DiaryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var content: String
    var mood: String  // Emoji or simple string
    var images: [String]  // Optional: Paths to locally stored images (for future use)

    init(
        id: UUID = UUID(), date: Date = Date(), content: String, mood: String = "🌱",
        images: [String] = []
    ) {
        self.id = id
        self.date = date
        self.content = content
        self.mood = mood
        self.images = images
    }
}
