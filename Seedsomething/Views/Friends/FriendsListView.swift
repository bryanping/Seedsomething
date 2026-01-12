//
//  FriendsListView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI

struct FriendsListView: View {
    @EnvironmentObject var plantManager: PlantManager
    @State private var showAddFriend = false
    @State private var selectedFriend: Friend?
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.brandLightGreen.ignoresSafeArea()
                
                if plantManager.friends.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.brandGrayGreen.opacity(0.5))
                        
                        Text("還沒有好友")
                            .font(.custom("PingFang TC", size: 18))
                            .foregroundColor(.brandDarkGray)
                        
                        Text("添加好友，一起種草吧！")
                            .font(.custom("PingFang TC", size: 14))
                            .foregroundColor(.brandDarkGray.opacity(0.6))
                        
                        Button(action: {
                            showAddFriend = true
                        }) {
                            Text("添加好友")
                                .font(.custom("PingFang TC", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 140, height: 44)
                                .background(Color.brandLightGreen)
                                .cornerRadius(22)
                                .shadow(color: Color.brandLightGreen.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                    }
                } else {
                    // 好友列表
                    List {
                        ForEach(plantManager.friends) { friend in
                            Button(action: {
                                selectedFriend = friend
                            }) {
                                HStack(spacing: 15) {
                                    // 头像
                                    if let avatarUrl = friend.friendAvatarUrl, let url = URL(string: avatarUrl) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(.brandGrayGreen)
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.brandGrayGreen.opacity(0.5))
                                            .frame(width: 50, height: 50)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(friend.friendNickname)
                                            .font(.custom("PingFang TC", size: 16))
                                            .fontWeight(.medium)
                                            .foregroundColor(.brandDarkGray)
                                        
                                        if let lastInteraction = friend.lastInteractionAt {
                                            Text("上次互動: \(formatDate(lastInteraction))")
                                                .font(.custom("PingFang TC", size: 12))
                                                .foregroundColor(.brandDarkGray.opacity(0.6))
                                        } else {
                                            Text("還沒有互動過")
                                                .font(.custom("PingFang TC", size: 12))
                                                .foregroundColor(.brandDarkGray.opacity(0.6))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.brandGrayGreen)
                                        .font(.caption)
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(Color.white.opacity(0.6))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("好友")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.brandDarkGray)
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView()
            }
            .sheet(item: $selectedFriend) { friend in
                FriendGardenView(friend: friend)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    FriendsListView()
        .environmentObject(PlantManager.shared)
}
