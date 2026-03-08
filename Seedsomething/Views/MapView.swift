//
//  MapView.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import CoreLocation
import FirebaseFirestore
import MapKit
import SwiftUI
import UIKit

struct MapView: View {
    @EnvironmentObject var plantManager: PlantManager
    @StateObject private var locationManager = LocationManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),  // 初始值，等待GPS定位
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)  // 放大地图（减小可视范围）
    )
    @State private var selectedRecord: PlantRecord?
    @State private var selectedRecordUserInfo: UserInfo?  // 选中的记录的用户信息
    @State private var isZoomedOut: Bool = false  // 缩放状态监测
    @State private var isPlanting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showWaterSuccess = false
    @State private var showLocationPermissionAlert = false
    @State private var mapCenterCoordinate: MapCoordinate = MapCoordinate(
        latitude: 0, longitude: 0)  // 用于 onChange 的可观察坐标
    @State private var friendsCount: Int = 0  // 用于 onChange 的朋友数量
    @State private var hasSetInitialCenter = false  // 标记是否已设置初始中心

    /// 地图筛选：热门草 / 最近草 / 朋友草
    enum MapFilterType: String, CaseIterable {
        case hot = "熱門"
        case recent = "最近"
        case friend = "朋友"
    }
    @State private var filterType: MapFilterType = .hot

    /// 点击草丛后放大的网格 key，用于分解显示单草
    @State private var selectedClusterGridKey: String? = nil
    /// 当前选中的草丛（用于详情页）
    @State private var selectedCluster: ClusterEntry? = nil

    /// 草丛密度阈值：同一网格内 ≥ 此数量则显示为草丛
    private let clusterThreshold = 8
    /// 网格大小约 100m（0.001 经纬度）
    private let gridScale = 1000.0

    var body: some View {
        NavigationView {
            ZStack {
                // 地图视图（使用 LocationManager 获取用户位置）
                mapView

                // 顶部筛选：热门 / 最近 / 朋友
                VStack {
                    Picker("篩選", selection: $filterType) {
                        ForEach(MapView.MapFilterType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    Spacer()
                }

                // 底部卡片（显示小草详细信息）
                if let record = selectedRecord, let userInfo = selectedRecordUserInfo {
                    VStack {
                        Spacer()
                        PlantRecordDetailCard(
                            record: record,
                            userInfo: userInfo,
                            isFriend: plantManager.friends.contains(where: {
                                $0.friendUserId == record.userId
                            }),
                            onDismiss: {
                                selectedRecord = nil
                                selectedRecordUserInfo = nil
                            },
                            onAddFriend: {
                                addFriend(userId: record.userId, nickname: userInfo.nickname)
                            },
                            onRecordUpdated: { updated in
                                selectedRecord = updated
                            },
                            onWaterSuccess: { showWaterSuccess = true }
                        )
                        .padding(.bottom, 20)
                    }
                }

                // 右侧按钮组
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 15) {
                            // 回到我的位置按鈕
                            Button(action: {
                                moveToUserLocation()
                            }) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.brandLightGreen)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }

                            // GPS定位种草按钮（每日可99次）
                            Button(action: {
                                plantAtCurrentLocation()
                            }) {
                                VStack(spacing: 5) {
                                    Image(systemName: "leaf.fill")
                                        .font(.title3)
                                    Text("種草")
                                        .font(.custom("PingFang TC", size: 12))
                                }
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    isPlanting
                                        ? Color.brandGrayGreen
                                        : Color.brandLightGreen
                                )
                                .clipShape(Circle())
                                .shadow(radius: 5)
                            }
                            .disabled(isPlanting)
                            .opacity(isPlanting ? 0.6 : 1.0)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("錯誤", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("種草成功", isPresented: $showSuccess) {
                Button("確定", role: .cancel) {}
            } message: {
                Text("在當前位置種下了一顆草 🌱")
            }
            .alert("幫澆水成功", isPresented: $showWaterSuccess) {
                Button("確定", role: .cancel) {}
            } message: {
                Text("已為這棵草澆水，你的露珠 +1 💧")
            }
            .onAppear {
                // 请求定位权限
                locationManager.requestWhenInUseAuthorization()

                // 开始更新位置
                locationManager.startUpdatingLocation()

                // 设置初始地图中心
                setupInitialMapCenter()

                // 初始化朋友数量
                friendsCount = plantManager.friends.count

                // 加载朋友的打卡记录（永远可见）
                Task {
                    await plantManager.loadFriendPlantRecords()
                }

                // 加载附近范围内的打卡记录（如果少于10个会自动扩大范围）
                // 仅当已有位置时加载；否则等待 .onChange(of: locationManager.lastLocation) 触发
                if let userLocation = locationManager.lastLocation?.coordinate {
                    Task {
                        do {
                            try await plantManager.loadNearbyPlantRecords(
                                center: userLocation, initialRadiusKm: 3.0)
                            print("✅ 成功加载 \(plantManager.allUsersPlantRecords.count) 条附近打卡记录")
                        } catch {
                            print("❌ 加载附近打卡记录失败: \(error.localizedDescription)")
                            if error.localizedDescription.contains("index") {
                                print("💡 提示：需要在 Firebase Console 中创建复合索引")
                            }
                        }
                    }
                }
            }
            .onDisappear {
                // 停止更新位置以节省电量
                locationManager.stopUpdatingLocation()
            }
            .onChange(of: locationManager.lastLocation) { newLocation in
                // 當位置更新時，更新 PlantManager 的 currentLocation
                guard let location = newLocation else { return }
                let coordinate = location.coordinate
                plantManager.updateCurrentLocation(coordinate)

                // 如果是第一次獲取到精準 GPS 定位，設置地圖中心並載入數據
                // 精準度要求：100米以內
                if !hasSetInitialCenter && location.horizontalAccuracy > 0
                    && location.horizontalAccuracy < 100
                {
                    print("📍 獲取到精準定位 (精準度: \(Int(location.horizontalAccuracy))m)，啟動地圖...")
                    withAnimation {
                        region.center = coordinate
                        mapCenterCoordinate = MapCoordinate(
                            latitude: coordinate.latitude, longitude: coordinate.longitude)
                    }
                    hasSetInitialCenter = true

                    // 只在第一次精準定位時載入數據
                    Task {
                        try? await plantManager.loadNearbyPlantRecords(
                            center: coordinate, initialRadiusKm: 3.0)
                    }
                }
                // 注意：後續位置更新不再自動載入，避免頻繁查詢
            }

            .onChange(of: mapCenterCoordinate) { newCoordinate in
                // 当地图中心改变时，检查是否需要重新加载
                // 只有当移动距离超过1公里时才重新加载，避免频繁查询
                let center = CLLocationCoordinate2D(
                    latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)

                // 检查与上次加载位置的距离
                if let lastCenter = plantManager.currentLocation {
                    let distance =
                        CLLocation(latitude: center.latitude, longitude: center.longitude)
                        .distance(
                            from: CLLocation(
                                latitude: lastCenter.latitude, longitude: lastCenter.longitude))
                        / 1000.0

                    // 只有移动超过1公里才重新加载
                    if distance > 1.0 {
                        Task {
                            try? await plantManager.loadNearbyPlantRecords(
                                center: center, initialRadiusKm: 3.0)
                        }
                    }
                } else {
                    // 如果没有上次位置，直接加载
                    Task {
                        try? await plantManager.loadNearbyPlantRecords(
                            center: center, initialRadiusKm: 3.0)
                    }
                }
            }

            .onChange(of: friendsCount) { _ in
                // 当朋友列表改变时，重新加载朋友的打卡记录
                Task {
                    await plantManager.loadFriendPlantRecords()
                }
            }

            .onChange(of: plantManager.friends.count) { newCount in
                // 更新朋友数量以触发 onChange
                friendsCount = newCount
            }
            .alert("定位權限", isPresented: $showLocationPermissionAlert) {
                Button("設定", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text(locationManager.errorMessage ?? "需要定位權限才能顯示您的位置")
            }
            .sheet(item: $selectedCluster) { entry in
                ClusterDetailSheet(entry: entry, onDismiss: { selectedCluster = nil })
            }
        }
    }

    // 地图视图（根据地区选择 Apple MapKit 或高德地图）
    private var mapView: some View {
        // 根据地区选择地图服务
        if MapService.shared.isInMainlandChina {
            // 中国大陆：使用高德地图（需要集成 SDK）
            // 目前先使用 Apple MapKit，集成高德地图 SDK 后可以切换
            appleMapView
        } else {
            // 其他地区：使用 Apple MapKit
            appleMapView
        }
    }

    /// 按筛选类型得到的非朋友记录（有效坐标 + 非好友）
    private var filteredNonFriendRecords: [PlantRecord] {
        let base = plantManager.allUsersPlantRecords.filter { record in
            let valid = record.coordinate.latitude != 0 && record.coordinate.longitude != 0
                && record.coordinate.latitude >= -90 && record.coordinate.latitude <= 90
                && record.coordinate.longitude >= -180 && record.coordinate.longitude <= 180
            let notFriend = !plantManager.friends.contains(where: { $0.friendUserId == record.userId })
            return valid && notFriend
        }
        switch filterType {
        case .hot: return base.sorted { $0.waterCount + $0.visitCount > $1.waterCount + $1.visitCount }
        case .recent: return base.sorted { $0.createdAt > $1.createdAt }
        case .friend: return []
        }
    }

    /// 按筛选类型得到的朋友记录
    private var filteredFriendRecords: [PlantRecord] {
        let base = plantManager.friendPlantRecords.filter { record in
            record.coordinate.latitude != 0 && record.coordinate.longitude != 0
                && record.coordinate.latitude >= -90 && record.coordinate.latitude <= 90
                && record.coordinate.longitude >= -180 && record.coordinate.longitude <= 180
        }
        switch filterType {
        case .hot: return base.sorted { $0.waterCount + $0.visitCount > $1.waterCount + $1.visitCount }
        case .recent: return base.sorted { $0.createdAt > $1.createdAt }
        case .friend: return base
        }
    }

    private func gridKey(for record: PlantRecord) -> String {
        "\(Int(floor(record.coordinate.latitude * gridScale)))_\(Int(floor(record.coordinate.longitude * gridScale)))"
    }

    private func clusterGroups(from records: [PlantRecord]) -> [String: [PlantRecord]] {
        Dictionary(grouping: records, by: { gridKey(for: $0) })
    }

    private func clusterCenter(for records: [PlantRecord]) -> CLLocationCoordinate2D? {
        guard !records.isEmpty else { return nil }
        let lat = records.map(\.coordinate.latitude).reduce(0, +) / Double(records.count)
        let lng = records.map(\.coordinate.longitude).reduce(0, +) / Double(records.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private func visibleIndividualRecords(from records: [PlantRecord], clusterGroups: [String: [PlantRecord]]) -> [PlantRecord] {
        records.filter { record in
            let key = gridKey(for: record)
            let count = clusterGroups[key]?.count ?? 0
            if count >= clusterThreshold { return selectedClusterGridKey == key }
            return true
        }
    }

    /// 草丛条目（用于 ForEach）
    struct ClusterEntry: Identifiable {
        let id: String
        let records: [PlantRecord]
    }

    private var clusterEntriesToShow: [ClusterEntry] {
        let all = filteredFriendRecords + filteredNonFriendRecords
        let groups = clusterGroups(from: all)
        return groups.compactMap { pair in
            guard pair.value.count >= clusterThreshold, pair.key != selectedClusterGridKey else { return nil }
            return ClusterEntry(id: pair.key, records: pair.value)
        }
    }

    // Apple MapKit 地图视图
    private var appleMapView: some View {
        Map {
            // 显示用户位置（使用 LocationManager）
            if let userLocation = locationManager.lastLocation?.coordinate {
                Annotation("我的位置", coordinate: userLocation) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }

            // 草丛标注（密度 ≥ 8 的网格）
            ForEach(clusterEntriesToShow) { entry in
                if let center = clusterCenter(for: entry.records) {
                    Annotation("草叢", coordinate: center) {
                        Button(action: {
                            selectedClusterGridKey = entry.id
                            selectedCluster = entry
                            withAnimation {
                                region.center = center
                                region.span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                            }
                        }) {
                            ClusterPinView(count: entry.records.count)
                        }
                    }
                }
            }

            // 显示所有用户的打卡记录（陌生人，附近范围内）- 支持筛选
            ForEach(visibleIndividualRecords(from: filteredNonFriendRecords, clusterGroups: clusterGroups(from: filteredFriendRecords + filteredNonFriendRecords))) { record in
                Annotation("种草记录", coordinate: record.coordinate.clLocationCoordinate2D) {
                    Button(action: {
                        selectedRecord = record
                        loadUserInfo(for: record.userId)
                    }) {
                        GrassPointView(waterCount: record.waterCount, isZoomedOut: isZoomedOut)
                    }
                }
            }

            // 显示朋友的打卡记录 - 支持筛选
            ForEach(visibleIndividualRecords(from: filteredFriendRecords, clusterGroups: clusterGroups(from: filteredFriendRecords + filteredNonFriendRecords))) { record in
                Annotation("朋友的草", coordinate: record.coordinate.clLocationCoordinate2D) {
                    Button(action: {
                        selectedRecord = record
                        loadUserInfo(for: record.userId)
                    }) {
                        // 朋友的草
                        if isZoomedOut {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                                .shadow(radius: 1)
                        } else {
                            GrassPointView(waterCount: record.waterCount, isZoomedOut: false)
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                )
                        }
                    }
                }
            }
        }
        .mapStyle(.standard)
        .onMapCameraChange(frequency: .onEnd) { context in
            // 监测缩放级别
            let altitude = context.camera.distance
            withAnimation(.easeInOut(duration: 0.3)) {
                isZoomedOut = altitude > 20000
            }

            // 使用防抖：只在相机移动结束后更新
            let newCenter = context.region.center
            let newCoordinate = MapCoordinate(
                latitude: newCenter.latitude, longitude: newCenter.longitude)

            // 检查坐标
            let distance =
                CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude)
                .distance(
                    from: CLLocation(
                        latitude: region.center.latitude, longitude: region.center.longitude))
                / 1000.0

            // 只有移动超过500米才更新
            if distance > 0.5 {
                region = MKCoordinateRegion(
                    center: newCenter,
                    span: context.region.span
                )
                mapCenterCoordinate = newCoordinate
            }
        }
        .ignoresSafeArea()
    }

    // 移动到用户位置
    private func moveToUserLocation() {
        guard let location = locationManager.lastLocation?.coordinate else {
            // 检查定位权限
            if locationManager.authorizationStatus == .denied
                || locationManager.authorizationStatus == .restricted
            {
                showLocationPermissionAlert = true
            } else {
                errorMessage = "無法獲取當前位置，請確保已開啟定位權限"
                showError = true
            }
            return
        }

        withAnimation {
            region.center = location
        }
    }

    // 设置初始地图中心（使用GPS定位）
    private func setupInitialMapCenter() {
        // 优先使用用户当前位置（GPS定位）
        if let userLocation = locationManager.lastLocation?.coordinate {
            withAnimation {
                region.center = userLocation
                mapCenterCoordinate = MapCoordinate(
                    latitude: userLocation.latitude, longitude: userLocation.longitude)
            }
            hasSetInitialCenter = true
        } else {
            // 如果还没有GPS定位，等待位置更新
            // 位置更新会在 onChange(of: locationManager.lastLocation) 中处理
        }
    }

    // 加载用户信息
    private func loadUserInfo(for userId: String) {
        Task {
            do {
                // 从 Firebase 加载用户信息
                let firestore = FirestoreManager.shared.db
                let userDoc = try await firestore.collection("users").document(userId).getDocument()

                if userDoc.exists, let data = userDoc.data() {
                    let nickname = data["nickname"] as? String ?? "未知用户"
                    // 加载用户的小草数据
                    let grass = try? await FirebaseService.shared.loadGrass(userId: userId)

                    await MainActor.run {
                        selectedRecordUserInfo = UserInfo(
                            userId: userId,
                            nickname: nickname,
                            grass: grass
                        )
                    }
                } else {
                    await MainActor.run {
                        selectedRecordUserInfo = UserInfo(
                            userId: userId,
                            nickname: "未知用户",
                            grass: nil
                        )
                    }
                }
            } catch {
                print("加载用户信息失败: \(error.localizedDescription)")
                await MainActor.run {
                    selectedRecordUserInfo = UserInfo(
                        userId: userId,
                        nickname: "未知用户",
                        grass: nil
                    )
                }
            }
        }
    }

    // 添加好友
    private func addFriend(userId: String, nickname: String) {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            errorMessage = "請先登入"
            showError = true
            return
        }

        // 检查是否已经是好友
        if plantManager.friends.contains(where: { $0.friendUserId == userId }) {
            errorMessage = "已經是好友了"
            showError = true
            return
        }

        // 检查是否是自己
        if userId == currentUserId {
            errorMessage = "不能添加自己為好友"
            showError = true
            return
        }

        // 创建好友关系
        let friend = Friend(
            userId: currentUserId,
            friendUserId: userId,
            friendNickname: nickname
        )

        plantManager.addFriend(friend)

        // 显示成功消息
        showSuccess = true
        errorMessage = "已添加 \(nickname) 為好友"
    }

    // 在当前 GPS 位置种草
    private func plantAtCurrentLocation() {
        guard let location = locationManager.lastLocation?.coordinate else {
            // 检查定位权限
            if locationManager.authorizationStatus == .denied
                || locationManager.authorizationStatus == .restricted
            {
                showLocationPermissionAlert = true
            } else {
                errorMessage = "無法獲取當前位置，請確保已開啟定位權限"
                showError = true
            }
            return
        }

        isPlanting = true
        Task {
            do {
                try await plantManager.plantAtLocation(location)
                showSuccess = true
                // 更新地图中心到当前位置
                withAnimation {
                    region.center = location
                }
            } catch let error as NSError {
                // 检查是否是权限错误
                if error.domain == "FirebaseService" && error.code == 403 {
                    errorMessage =
                        "权限不足：无法保存到地图。\n\n请检查 Firebase Console 中的 Firestore 安全规则设置。\n\n参考：FIREBASE_SECURITY_RULES.md"
                } else {
                    errorMessage = error.localizedDescription
                }
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPlanting = false
        }
    }
}

// 用户信息结构
struct UserInfo {
    let userId: String
    let nickname: String
    let grass: Grass?
}

// 可观察的坐标结构（用于 onChange）
struct MapCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}

// 草丛标注视图（点击放大并分解为单草）
struct ClusterPinView: View {
    let count: Int
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.brandLightGreen.opacity(0.9))
                .frame(width: 44, height: 44)
                .overlay(
                    Text("\(count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(radius: 3)
        }
    }
}

// 草丛详情页：该区域草数量、总互动、今日新增、热度
struct ClusterDetailSheet: View {
    let entry: MapView.ClusterEntry
    let onDismiss: () -> Void
    private var totalWater: Int { entry.records.reduce(0) { $0 + $1.waterCount } }
    private var totalVisit: Int { entry.records.reduce(0) { $0 + $1.visitCount } }
    private var todayCount: Int { entry.records.filter { Calendar.current.isDateInToday($0.createdAt) }.count }
    private var heatIndex: Int { totalWater + totalVisit }
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "leaf.fill").foregroundColor(.brandLightGreen).frame(width: 28)
                    Text("草數量").font(.custom("PingFang TC", size: 16)).foregroundColor(.brandDarkGray.opacity(0.8))
                    Spacer()
                    Text("\(entry.records.count)").font(.custom("PingFang TC", size: 18)).fontWeight(.medium).foregroundColor(.brandDarkGray)
                }
                HStack {
                    Image(systemName: "drop.fill").foregroundColor(.brandLightGreen).frame(width: 28)
                    Text("總澆水次數").font(.custom("PingFang TC", size: 16)).foregroundColor(.brandDarkGray.opacity(0.8))
                    Spacer()
                    Text("\(totalWater)").font(.custom("PingFang TC", size: 18)).fontWeight(.medium).foregroundColor(.brandDarkGray)
                }
                HStack {
                    Image(systemName: "person.2.fill").foregroundColor(.brandLightGreen).frame(width: 28)
                    Text("總互動次數").font(.custom("PingFang TC", size: 16)).foregroundColor(.brandDarkGray.opacity(0.8))
                    Spacer()
                    Text("\(totalVisit)").font(.custom("PingFang TC", size: 18)).fontWeight(.medium).foregroundColor(.brandDarkGray)
                }
                HStack {
                    Image(systemName: "sparkles").foregroundColor(.brandLightGreen).frame(width: 28)
                    Text("今日新增草").font(.custom("PingFang TC", size: 16)).foregroundColor(.brandDarkGray.opacity(0.8))
                    Spacer()
                    Text("\(todayCount)").font(.custom("PingFang TC", size: 18)).fontWeight(.medium).foregroundColor(.brandDarkGray)
                }
                HStack {
                    Image(systemName: "flame.fill").foregroundColor(.brandLightGreen).frame(width: 28)
                    Text("熱度指數").font(.custom("PingFang TC", size: 16)).foregroundColor(.brandDarkGray.opacity(0.8))
                    Spacer()
                    Text("\(heatIndex)").font(.custom("PingFang TC", size: 18)).fontWeight(.medium).foregroundColor(.brandDarkGray)
                }
                Spacer()
            }
            .padding(20)
            .navigationTitle("草叢")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("關閉") { onDismiss() } } }
        }
    }
}

// 小草详细信息卡片
struct PlantRecordDetailCard: View {
    let record: PlantRecord
    let userInfo: UserInfo
    let isFriend: Bool
    let onDismiss: () -> Void
    let onAddFriend: () -> Void
    var onRecordUpdated: ((PlantRecord) -> Void)? = nil
    var onWaterSuccess: (() -> Void)? = nil

    @EnvironmentObject private var plantManager: PlantManager
    @State private var messageText: String = ""
    @State private var isWatering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(userInfo.nickname)
                        .font(.custom("PingFang TC", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.brandDarkGray)

                    Text(formatDate(record.createdAt))
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGray.opacity(0.6))
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.brandDarkGray.opacity(0.5))
                        .font(.title3)
                }
            }

            Divider()

            // 互动人数、总浇水次数
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.brandLightGreen)
                    Text("互動 \(record.visitCount) 人")
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGray)
                }
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text("澆水 \(record.waterCount) 次")
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGray)
                }
            }

            Divider()

            // 小草状态信息
            if let grass = userInfo.grass {
                VStack(alignment: .leading, spacing: 10) {
                    // 小草等级
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("等級 \(grass.level)")
                            .font(.custom("PingFang TC", size: 16))
                            .foregroundColor(.brandDarkGray)
                    }

                    // 扩张范围（根据等级计算）
                    HStack {
                        Image(systemName: "circle.grid.3x3.fill")
                            .foregroundColor(.brandLightGreen)
                        Text("擴張範圍: \(calculateExpansionRadius(level: grass.level)) 公尺")
                            .font(.custom("PingFang TC", size: 16))
                            .foregroundColor(.brandDarkGray)
                    }

                    // 连续天数
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("連續 \(grass.consecutiveDays) 天")
                            .font(.custom("PingFang TC", size: 16))
                            .foregroundColor(.brandDarkGray)
                    }

                    // 小草状态
                    HStack {
                        Text(grass.mood.emoji)
                        Text(grass.mood.displayName)
                            .font(.custom("PingFang TC", size: 16))
                            .foregroundColor(.brandDarkGray)
                    }
                }
            } else {
                Text("小草信息載入中...")
                    .font(.custom("PingFang TC", size: 14))
                    .foregroundColor(.brandDarkGray.opacity(0.6))
            }

            // 添加好友按钮（如果不是好友且不是自己）
            if !isFriend && userInfo.userId != AuthManager.shared.currentUser?.id {
                Button(action: onAddFriend) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("添加好友")
                            .font(.custom("PingFang TC", size: 16))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.brandLightGreen)
                    .cornerRadius(12)
                }
            } else if isFriend {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brandLightGreen)
                    Text("已是好友")
                        .font(.custom("PingFang TC", size: 16))
                        .foregroundColor(.brandDarkGray.opacity(0.6))
                }
            }

            if userInfo.userId != AuthManager.shared.currentUser?.id {
                Button(action: waterThisGrass) {
                    HStack {
                        Image(systemName: "drop.fill")
                        Text(plantManager.hasWateredPublicRecordToday(record.id) ? "今日已澆過" : "幫它澆水")
                            .font(.custom("PingFang TC", size: 16))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(plantManager.hasWateredPublicRecordToday(record.id) ? Color.gray : Color.brandLightGreen)
                    .cornerRadius(12)
                }
                .disabled(plantManager.hasWateredPublicRecordToday(record.id) || isWatering)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("留言")
                    .font(.custom("PingFang TC", size: 14))
                    .foregroundColor(.brandDarkGray.opacity(0.8))
                TextField("寫下一句...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveMessage() }
            }
        }
        .padding(20)
        .onAppear {
            messageText = record.message ?? ""
            plantManager.incrementVisitCount(for: record)
            if let u = plantManager.plantRecord(byId: record.id) { onRecordUpdated?(u) }
        }
        .onChange(of: plantManager.allUsersPlantRecords.count) { _ in
            if let u = plantManager.plantRecord(byId: record.id) { onRecordUpdated?(u) }
        }
        .onChange(of: plantManager.friendPlantRecords.count) { _ in
            if let u = plantManager.plantRecord(byId: record.id) { onRecordUpdated?(u) }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.brandGrayGreen.opacity(0.3), radius: 15, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }

    // 根据等级计算扩张范围（等级越高，范围越大）
    private func calculateExpansionRadius(level: Int) -> Int {
        return 10 + (level - 1) * 5
    }

    private func waterThisGrass() {
        isWatering = true
        Task {
            do {
                try await plantManager.waterPublicRecord(record)
                if let u = plantManager.plantRecord(byId: record.id) { onRecordUpdated?(u) }
                onWaterSuccess?()
            } catch {}
            isWatering = false
        }
    }

    private func saveMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        plantManager.updateRecordMessage(record, message: text.isEmpty ? nil : text)
        if let u = plantManager.plantRecord(byId: record.id) { onRecordUpdated?(u) }
    }
}

#Preview {
    MapView()
        .environmentObject(PlantManager.shared)
}
