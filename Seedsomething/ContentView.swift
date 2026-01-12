//
//  ContentView.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI

// RootView 已移至 SeedsomethingApp.swift

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("我的草")
                }
                .tag(0)
            
            MapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("地圖")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(2)
        }
        .accentColor(.brandLightGreen)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(PlantManager.shared)
}
