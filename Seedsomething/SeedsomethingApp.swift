//
//  SeedsomethingApp.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI

@main
struct SeedsomethingApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var plantManager = PlantManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(plantManager)
        }
    }
}
