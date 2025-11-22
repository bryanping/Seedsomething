//
//  MapView.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @EnvironmentObject var plantManager: PlantManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654), // 台北
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedRecord: PlantRecord?
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: plantManager.plantRecords) { record in
                    MapAnnotation(coordinate: record.coordinate.clLocationCoordinate2D) {
                        Button(action: {
                            selectedRecord = record
                        }) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.brandLightGreen)
                                .font(.title2)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 30, height: 30)
                                        .shadow(radius: 3)
                                )
                        }
                    }
                }
                .ignoresSafeArea()
                
                // 底部卡片
                if let record = selectedRecord {
                    VStack {
                        Spacer()
                        PlantRecordCard(record: record) {
                            selectedRecord = nil
                        }
                        .padding(.bottom, 20)
                    }
                }
                
                // 回到我的位置按鈕
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            if let location = plantManager.currentLocation {
                                withAnimation {
                                    region.center = location
                                }
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.brandLightGreen)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let location = plantManager.currentLocation {
                    region.center = location
                } else if let firstRecord = plantManager.plantRecords.first {
                    region.center = firstRecord.coordinate.clLocationCoordinate2D
                }
            }
        }
    }
}

struct PlantRecordCard: View {
    let record: PlantRecord
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(record.type == .personalCheckin ? "一般打卡" : "店家掃碼")
                        .font(.custom("PingFang TC", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.brandDarkGray)
                    
                    Text(formatDate(record.createdAt))
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGray.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.brandDarkGray.opacity(0.5))
                }
            }
            
            // 統計資訊
            HStack(spacing: 20) {
                Label {
                    Text("\(countAtLocation(record.coordinate)) 次")
                        .font(.custom("PingFang TC", size: 14))
                } icon: {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.brandLightGreen)
                }
            }
        }
        .padding(20)
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
    
    private func countAtLocation(_ coordinate: Coordinate) -> Int {
        // 簡化版：計算相同座標的記錄數（實際應該有更精確的邏輯）
        return 1
    }
}




#Preview {
    MapView()
}
