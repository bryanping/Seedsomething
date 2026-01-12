//
//  Untitled.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import AVFoundation
import SwiftUI

struct QRScannerView: View {
    @EnvironmentObject var plantManager: PlantManager
    @Environment(\.dismiss) var dismiss
    @State private var isScanning = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var storeName = ""

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // 相機預覽層（實際需要 CameraView）
            VStack {
                Text("對準店家的種草 QR")
                    .font(.custom("PingFang TC", size: 18))
                    .foregroundColor(.white)
                    .padding(.top, 50)

                Spacer()

                // QR Code 掃描框
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.brandLightGreen, lineWidth: 3)
                        .frame(width: 250, height: 250)

                    // 四個角落
                    CornerShape()
                        .stroke(Color.brandLightGreen, lineWidth: 4)
                        .frame(width: 250, height: 250)
                }

                Spacer()

                // 提示資訊
                VStack(spacing: 10) {
                    if let user = AuthManager.shared.currentUser {
                        Text("正在為 \(user.nickname) 種草")
                            .font(.custom("PingFang TC", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if let grass = plantManager.grass {
                        Text("Lv.\(grass.level) • EXP \(grass.exp)")
                            .font(.custom("PingFang TC", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 50)
            }

            // 成功畫面
            if showSuccess {
                SuccessView(storeName: storeName) {
                    showSuccess = false
                    dismiss()
                }
            }
        }
        .alert("錯誤", isPresented: $showError) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // TODO: 啟動相機掃描
            // 模擬掃描（測試用）
            simulateScan()
        }
    }

    private func simulateScan() {
        // 模擬掃描 QR Code
        // 實際應該使用 AVFoundation 的 AVCaptureSession
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            handleQRCode("test-store-token")
        }
    }

    private func handleQRCode(_ token: String) {
        guard let store = plantManager.findStoreByQRToken(token) else {
            errorMessage = "不是有效的種草 QR"
            showError = true
            return
        }

        Task {
            do {
                try await plantManager.scanAndPlant(storeId: store.id)
                storeName = store.name
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct CornerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerLength: CGFloat = 30

        // 左上角
        path.move(to: CGPoint(x: 0, y: cornerLength))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: cornerLength, y: 0))

        // 右上角
        path.move(to: CGPoint(x: rect.width - cornerLength, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: cornerLength))

        // 右下角
        path.move(to: CGPoint(x: rect.width, y: rect.height - cornerLength))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width - cornerLength, y: rect.height))

        // 左下角
        path.move(to: CGPoint(x: cornerLength, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height - cornerLength))

        return path
    }
}

struct SuccessView: View {
    let storeName: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 25) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.brandLightGreen)

                Text("你在 \(storeName) 小花園")
                    .font(.custom("PingFang TC", size: 20))
                    .foregroundColor(.white)

                Text("種下了一顆草 🌱")
                    .font(.custom("PingFang TC", size: 18))
                    .foregroundColor(.white.opacity(0.9))

                Button(action: onDismiss) {
                    Text("完成")
                        .font(.custom("PingFang TC", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 44)
                        .background(Color.brandLightGreen)
                        .cornerRadius(22)
                }
                .padding(.top, 20)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.brandDarkGray.opacity(0.9))
            )
            .padding(.horizontal, 40)
        }
    }
}
