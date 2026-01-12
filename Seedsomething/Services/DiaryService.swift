//
//  DiaryService.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import Foundation

/// 日記服務：負責本地 JSON 數據儲存
@MainActor
class DiaryService: ObservableObject {
    static let shared = DiaryService()

    @Published var entries: [DiaryEntry] = []

    private let fileName = "diary_entries.json"

    private init() {
        loadEntries()
    }

    /// 獲取文件 URL
    private var fileURL: URL? {
        guard
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }

    /// 加載日記
    func loadEntries() {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([DiaryEntry].self, from: data)
            print("✅ 成功加載 \(entries.count) 篇日記")
        } catch {
            print("❌ 加載日記失敗: \(error)")
        }
    }

    /// 保存日記
    func saveEntry(_ entry: DiaryEntry) {
        if let index = entries.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: entry.date)
        }) {
            // 如果當天已有日記，則更新
            entries[index] = entry
        } else {
            // 否則新增
            entries.append(entry)
            // 按日期倒序排列
            entries.sort { $0.date > $1.date }
        }

        persistToDisk()
    }

    /// 刪除日記
    func deleteEntry(at indexSet: IndexSet) {
        entries.remove(atOffsets: indexSet)
        persistToDisk()
    }

    /// 獲取指定日期的日記
    func getEntry(for date: Date) -> DiaryEntry? {
        return entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// 寫入磁盤
    private func persistToDisk() {
        guard let url = fileURL else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: url)
            print("✅ 日記已保存")
        } catch {
            print("❌ 保存日記失敗: \(error)")
        }
    }
}
