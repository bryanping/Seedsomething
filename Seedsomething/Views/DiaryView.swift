//
//  DiaryView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI

struct DiaryView: View {
    @StateObject private var diaryService = DiaryService.shared
    @State private var selectedDate = Date()
    @State private var entryText: String = ""
    @State private var selectedMood: String = "🌱"
    @State private var isEditing: Bool = false
    @Environment(\.presentationMode) var presentationMode

    let moods = ["🌱", "☀️", "🌧️", "🌈", "🥀", "🌻", "⭐", "💤"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 上半部分：编辑器
                editorSection
                    .padding(.top)
                    .background(Color.brandCream.opacity(0.3))

                Divider()

                // 下半部分：日历
                calendarSection
                    .background(Color.brandCream.opacity(0.1))
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("心情日記")
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.brandDarkGray)
                }
            )
            .onAppear {
                loadEntry(for: selectedDate)
            }
        }
    }

    // MARK: - Subviews

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            headerRow
                .padding(.horizontal)

            textEditorArea
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

            saveButton
        }
    }

    private var headerRow: some View {
        HStack {
            Text(formatDate(selectedDate))
                .font(.custom("PingFang TC", size: 24))
                .fontWeight(.bold)
                .foregroundColor(.brandDarkGray)

            Spacer()

            // Mood Picker
            Menu {
                ForEach(moods, id: \.self) { mood in
                    Button(action: {
                        selectedMood = mood
                    }) {
                        Text(mood)
                    }
                }
            } label: {
                Text(selectedMood)
                    .font(.system(size: 30))
                    .padding(8)
                    .background(Circle().fill(Color.brandLightGreen.opacity(0.2)))
            }
        }
    }

    private var textEditorArea: some View {
        ZStack(alignment: .topLeading) {
            if entryText.isEmpty && !isEditing {
                Text("寫下今天的心情...")
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(8)
            }

            TextEditor(text: $entryText)
                .font(.custom("PingFang TC", size: 16))
                .foregroundColor(.brandDarkGray)
                .background(Color.clear)
                .onTapGesture {
                    isEditing = true
                }
        }
    }

    private var saveButton: some View {
        Group {
            if isEditing || hasChanges() {
                Button(action: saveEntry) {
                    Text("保存日記")
                        .font(.custom("PingFang TC", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var calendarSection: some View {
        ScrollView {
            VStack {
                // Custom Calendar or DatePicker
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .accentColor(.white)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding()
                .onChange(of: selectedDate) { newDate in
                    loadEntry(for: newDate)
                }

                recentEntriesList
            }
        }
    }

    private var recentEntriesList: some View {
        VStack {
            Text("最近的記錄")
                .font(.custom("PingFang TC", size: 14))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 10)

            ForEach(diaryService.entries.prefix(5)) { entry in
                HStack {
                    Text(entry.mood)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(formatDateShort(entry.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(entry.content)
                            .font(.custom("PingFang TC", size: 14))
                            .lineLimit(1)
                            .foregroundColor(.brandDarkGray)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .onTapGesture {
                    selectedDate = entry.date
                }
            }
        }
    }

    // MARK: - Logic

    private func loadEntry(for date: Date) {
        isEditing = false
        if let entry = diaryService.getEntry(for: date) {
            entryText = entry.content
            selectedMood = entry.mood
        } else {
            entryText = ""
            selectedMood = "🌱"
        }
    }

    private func saveEntry() {
        let newEntry = DiaryEntry(
            date: selectedDate,
            content: entryText,
            mood: selectedMood
        )
        diaryService.saveEntry(newEntry)
        isEditing = false

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func hasChanges() -> Bool {
        if let existing = diaryService.getEntry(for: selectedDate) {
            return existing.content != entryText || existing.mood != selectedMood
        }
        return !entryText.isEmpty
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }

    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

#Preview {
    DiaryView()
}
