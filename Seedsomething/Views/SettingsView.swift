//
//  SettingsView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("外觀設定")) {
                    Picker("季節模式", selection: $settingsManager.seasonMode) {
                        ForEach(SeasonMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.white)
                    
                    if settingsManager.seasonMode == .manual {
                        Picker("選擇季節", selection: $settingsManager.manualSeason) {
                            ForEach(Season.allCases, id: \.self) { season in
                                Text(season.displayName).tag(season)
                            }
                        }
                        .pickerStyle(.menu)
                        .listRowBackground(Color.white)
                    }
                }
                
                Section(header: Text("關於")) {
                    HStack {
                        Text("當前版本")
                        Spacer()
                        Text("v1.0.0 (Alpha)")
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color.white)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.brandCream)
            .scrollContentBackground(.hidden) // 隐藏 Form 默认背景
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
