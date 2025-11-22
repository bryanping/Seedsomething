//
//  StoreGardenView.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct StoreGardenView: View {
    @EnvironmentObject var plantManager: PlantManager
    @Environment(\.dismiss) var dismiss
    @State private var storeName = ""
    @State private var address = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var createdStore: Store?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brandCream
                    .ignoresSafeArea()
                
                if let store = createdStore {
                    // 已建立店家花園的畫面
                    StoreGardenInfoView(store: store) {
                        createdStore = nil
                    }
                } else {
                    // 建立店家花園表單
                    ScrollView {
                        VStack(spacing: 25) {
                            Text("你可以為你的實體店鋪建立一座小花園，讓來店客人掃碼種草。")
                                .font(.custom("PingFang TC", size: 14))
                                .foregroundColor(.brandDarkGray.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .padding(.top, 30)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("店家名稱 *")
                                    .font(.custom("PingFang TC", size: 14))
                                    .foregroundColor(.brandDarkGray)
                                
                                TextField("輸入店家名稱", text: $storeName)
                                    .font(.custom("PingFang TC", size: 16))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                    )
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("地址")
                                    .font(.custom("PingFang TC", size: 14))
                                    .foregroundColor(.brandDarkGray)
                                
                                TextField("輸入地址（選填）", text: $address)
                                    .font(.custom("PingFang TC", size: 16))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                    )
                            }
                            .padding(.horizontal, 20)
                            
                            Button(action: {
                                createStore()
                            }) {
                                Text("建立店家花園")
                                    .font(.custom("PingFang TC", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(storeName.isEmpty ? Color.brandGrayGreen : Color.brandLightGreen)
                                    .cornerRadius(12)
                            }
                            .disabled(storeName.isEmpty || isCreating)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("錯誤", isPresented: $showError) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createStore() {
        guard !storeName.isEmpty else { return }
        
        isCreating = true
        
        // 使用當前位置或預設位置
        let coordinate: Coordinate
        if let location = plantManager.currentLocation {
            coordinate = Coordinate(location: location)
        } else {
            // 預設台北
            coordinate = Coordinate(latitude: 25.0330, longitude: 121.5654)
        }
        
        Task {
            do {
                let store = try await plantManager.createStore(name: storeName, coordinate: coordinate)
                createdStore = store
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isCreating = false
        }
    }
}

struct StoreGardenInfoView: View {
    let store: Store
    let onEdit: () -> Void
    @State private var qrCodeImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // 店家資訊
                VStack(spacing: 15) {
                    Text(store.name)
                        .font(.custom("PingFang TC", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.brandDarkGray)
                    
                    Text("總種草次數：\(store.totalPlantCount)")
                        .font(.custom("PingFang TC", size: 16))
                        .foregroundColor(.brandDarkGreen)
                }
                .padding(.top, 30)
                
                // QR Code
                VStack(spacing: 15) {
                    Text("店家專屬 QR Code")
                        .font(.custom("PingFang TC", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.brandDarkGray)
                    
                    if let qrImage = qrCodeImage {
                        Image(uiImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 250, height: 250)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.brandDarkGray, lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white)
                                    )
                            )
                    } else {
                        ProgressView()
                            .frame(width: 250, height: 250)
                    }
                    
                    Text("請將此 QR 貼在店內，讓客人掃碼種草")
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGray.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.vertical, 20)
                
                // 按鈕
                VStack(spacing: 15) {
                    Button(action: {
                        if let qrImage = qrCodeImage {
                            UIImageWriteToSavedPhotosAlbum(qrImage, nil, nil, nil)
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("儲存 QR 圖片")
                        }
                        .font(.custom("PingFang TC", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.brandLightGreen)
                        .cornerRadius(12)
                    }
                    .disabled(qrCodeImage == nil)
                    
                    Button(action: onEdit) {
                        Text("編輯店家資訊")
                            .font(.custom("PingFang TC", size: 16))
                            .foregroundColor(.brandDarkGray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brandGrayGreen, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        let data = store.qrCodeToken.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
}

