//
//  AddFriendView.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation
import AudioToolbox //修改内容：为 AudioServicesPlaySystemSound 引入

struct AddFriendView: View {
    @EnvironmentObject var plantManager: PlantManager
    @Environment(\.dismiss) var dismiss
    @State private var searchId: String = ""
    @State private var isShowingScanner = false
    @State private var scannedCode: String?
    @State private var searchResult: User?
    @State private var showNotFoundAlert = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    
    // 生成二维码
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("輸入好友 ID 搜尋", text: $searchId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    if !searchId.isEmpty {
                        Button(action: { searchId = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.brandLightGreen)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button(action: performSearch) {
                    Text("搜尋")
                        .font(.custom("PingFang TC", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.brandLightGreen)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(searchId.isEmpty)
                
                Divider().padding(.vertical)
                
                // 我的二维码
                VStack(spacing: 15) {
                    Text("我的 ID 二維碼")
                        .font(.custom("PingFang TC", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.brandDarkGray)
                    
                    if let userId = AuthManager.shared.currentUser?.id,
                       let qrImage = generateQRCode(from: userId) {
                        Image(uiImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .shadow(radius: 5)
                    }
                    
                    Text("讓朋友掃描以添加我")
                        .font(.custom("PingFang TC", size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 扫一扫按钮
                Button(action: {
                    isShowingScanner = true
                }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("掃一掃")
                    }
                    .font(.custom("PingFang TC", size: 16))
                    .foregroundColor(.brandDarkGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.brandGrayGreen.opacity(0.2))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("添加好友")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            .alert("未找到用戶", isPresented: $showNotFoundAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text("請檢查 ID 是否正確")
            }
            .sheet(isPresented: $isShowingScanner) {
                AddFriendQRScannerView { code in //修改内容：改用新名字，避免同名冲突
                    self.searchId = code
                    self.isShowingScanner = false
                    self.performSearch()
                }
            }
            .sheet(item: $searchResult) { user in
                SearchResultView(user: user)
            }
        }
    }
    
    private func performSearch() {
        Task {
            do {
                if let user = try await plantManager.searchUser(by: searchId) {
                    searchResult = user
                } else {
                    showNotFoundAlert = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            // 放大
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

// 简单的搜索结果视图
struct SearchResultView: View {
    let user: User
    @EnvironmentObject var plantManager: PlantManager
    @Environment(\.dismiss) var dismiss
    @State private var isAdding = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundColor(.brandGrayGreen)
                .frame(width: 80, height: 80)
            
            Text(user.nickname)
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: addFriend) {
                HStack {
                    if isAdding {
                        ProgressView()
                    } else {
                        Text("添加好友")
                    }
                }
                .frame(width: 200, height: 44)
                .background(Color.brandLightGreen)
                .foregroundColor(.white)
                .cornerRadius(22)
            }
            .disabled(isAdding)
        }
        .padding()
    }
    
    private func addFriend() {
        isAdding = true
        Task {
            let friend = Friend(
                userId: AuthManager.shared.currentUser?.id ?? "",
                friendUserId: user.id,
                friendNickname: user.nickname
            )
            plantManager.addFriend(friend)
            isAdding = false
            dismiss()
        }
    }
}

// 简单的 QR 扫描器
struct AddFriendQRScannerView: UIViewControllerRepresentable { //修改内容：改名，避免 QRScannerView 同名冲突
    var didFindCode: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scanner = ScannerViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        var parent: AddFriendQRScannerView //修改内容：类型名同步
        
        init(parent: AddFriendQRScannerView) { //修改内容：类型名同步
            self.parent = parent
        }
        
        func didFind(code: String) {
            parent.didFindCode(code)
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFind(code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: ScannerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFind(code: stringValue)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
}
