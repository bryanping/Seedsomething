//
//  AuthManager.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

/// 認證管理器
/// 使用 @MainActor 確保所有狀態更新在主線程
@MainActor
class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false

    /// 若為 true，下一次 Apple 授權完成後會執行「連結帳號」而非登入
    private var isLinkingApple: Bool = false

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String? = nil

    private override init() {
        super.init()
        // 监听 Firebase Auth 状态变化
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener {
            [weak self] auth, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    // 用户已登录 Firebase
                    await self?.loadUserFromFirebase(firebaseUser: firebaseUser)
                } else {
                    // 用户未登录
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }

    // Apple Sign In with Firebase
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        // 生成 nonce，并写入 request    // 修改内容
        let nonce = randomNonceString()  // 修改内容
        currentNonce = nonce  // 修改内容
        request.nonce = sha256(nonce)  // 修改内容

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // 生成 nonce（供外部使用，如 SignInWithAppleButton）
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }

    // 处理 Apple Sign In 结果（用于 SignInWithAppleButton）
    func handleAppleSignInResult(credential: ASAuthorizationAppleIDCredential) async {
        await signInWithAppleCredential(credential: credential)
    }

    // Google Sign In (需要額外配置)
    func signInWithGoogle() {
        // TODO: 實現 Google Sign In with Firebase
        // 暫時使用匿名登入
        Task {
            await signInAnonymously()
        }
    }

    // Firebase 匿名登录（用于测试）
    private func signInAnonymously() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            await loadUserFromFirebase(firebaseUser: result.user)
        } catch {
            print("匿名登录失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 邮箱密码登录

    /// 使用邮箱和密码注册新用户
    func signUpWithEmail(email: String, password: String, nickname: String) async throws {
        // 创建用户
        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        // 更新显示名称
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = nickname
        try await changeRequest.commitChanges()

        // 保存用户信息到 Firestore
        let firestore = Firestore.firestore()
        try await firestore.collection("users").document(result.user.uid).setData([
            "id": result.user.uid,
            "nickname": nickname,
            "email": email,
            "createdAt": Timestamp(date: Date()),
        ])

        // 加载用户数据
        await loadUserFromFirebase(firebaseUser: result.user)
    }

    /// 使用邮箱和密码登录
    func signInWithEmail(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await loadUserFromFirebase(firebaseUser: result.user)
    }

    /// 重置密码
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - 帳號綁定（多登入方式）

    /// 已綁定的登入方式對應顯示名稱
    var linkedAuthProviderNames: [(id: String, displayName: String)] {
        guard let user = Auth.auth().currentUser else { return [] }
        return user.providerData
            .map { info in (id: info.providerID, displayName: authProviderDisplayName(info.providerID)) }
            .filter { $0.displayName != "" }
    }

    /// 是否已綁定指定方式
    func isLinked(providerId: String) -> Bool {
        Auth.auth().currentUser?.providerData.contains { $0.providerID == providerId } ?? false
    }

    /// 當前 Firebase 用戶的電子郵件（可能為空）
    var currentUserEmail: String? { Auth.auth().currentUser?.email }

    private func authProviderDisplayName(_ providerId: String) -> String {
        switch providerId {
        case "apple.com": return "Apple"
        case "password": return "電子郵件"
        case "google.com": return "Google"
        default: return ""
        }
    }

    /// 開始「連結 Apple」流程（需已登入）
    func startLinkWithApple() {
        guard Auth.auth().currentUser != nil else { return }
        isLinkingApple = true
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    /// 連結電子郵件帳號（需已登入）
    func linkWithEmail(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "請先登入"])
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        let result = try await user.link(with: credential)
        await loadUserFromFirebase(firebaseUser: result.user)
    }

    /// 連結 Apple 憑證（由 Apple 授權完成後呼叫）
    private func linkWithAppleCredential(credential: ASAuthorizationAppleIDCredential) async {
        guard let nonce = currentNonce,
              let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8),
              let firebaseUser = Auth.auth().currentUser
        else {
            isLinkingApple = false
            return
        }
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        do {
            let result = try await firebaseUser.link(with: firebaseCredential)
            await loadUserFromFirebase(firebaseUser: result.user)
        } catch {
            print("連結 Apple 失敗: \(error.localizedDescription)")
        }
        isLinkingApple = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            print("登出失败: \(error.localizedDescription)")
        }
    }

    // 从 Firebase 加载用户数据
    private func loadUserFromFirebase(firebaseUser: FirebaseAuth.User) async {
        let userId = firebaseUser.uid
        let displayName =
            firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first
            ?? "新草"

        // 从 Firestore 加载用户详细信息
        do {
            // 使用 FirestoreManager 獲取 Firestore 實例
            let firestore = FirestoreManager.shared.db
            let userDoc = try await firestore.collection("users").document(userId).getDocument()

            if userDoc.exists, let data = userDoc.data() {
                // 从 Firestore 加载用户数据
                let nickname = data["nickname"] as? String ?? displayName
                currentUser = User(id: userId, nickname: nickname)
            } else {
                // 创建新用户
                let user = User(id: userId, nickname: displayName)
                currentUser = user

                // 保存到 Firestore
                try await firestore.collection("users").document(userId).setData([
                    "id": userId,
                    "nickname": displayName,
                    "createdAt": Timestamp(date: Date()),
                ])
            }

            isAuthenticated = true
        } catch {
            print("加载用户数据失败: \(error.localizedDescription)")
            // 即使加载失败，也创建基本用户对象，但不标记为已认证
            currentUser = User(id: userId, nickname: displayName)
            isAuthenticated = false
        }
    }
    // MARK: - Apple Sign In Nonce 工具

    /// 隨機字串，作為 Apple Sign In 的 nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }

        return result
    }

    /// 對 nonce 做 SHA256，用於 request.nonce
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            Task {
                if isLinkingApple {
                    await linkWithAppleCredential(credential: appleIDCredential)
                } else {
                    await signInWithAppleCredential(credential: appleIDCredential)
                }
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        isLinkingApple = false
        // 处理 Apple Sign In 错误
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                print("Apple Sign In: 用户取消了登录")
            case .failed:
                print("Apple Sign In 錯誤: 授权失败")
            case .invalidResponse:
                print("Apple Sign In 錯誤: 无效的响应")
            case .notHandled:
                print("Apple Sign In 錯誤: 请求未处理")
            case .unknown:
                print("Apple Sign In 錯誤: 未知错误")
            @unknown default:
                print("Apple Sign In 錯誤: \(error.localizedDescription)")
            }
        } else {
            print("Apple Sign In 錯誤: \(error.localizedDescription)")
        }
    }

    // 使用 Apple ID Credential 登录 Firebase
    private func signInWithAppleCredential(credential: ASAuthorizationAppleIDCredential) async {
        // 1. 取回 nonce
        guard let nonce = currentNonce else {  // 修改内容
            print("缺少 nonce，請重新嘗試登入")  // 修改内容
            return
        }

        // 2. 取回 Apple ID token
        guard let identityToken = credential.identityToken,
            let idTokenString = String(data: identityToken, encoding: .utf8)
        else {
            print("無法取得 Apple ID Token")
            return
        }

        // 昵称（沒名字就給一個預設）
        let fullName = credential.fullName
        let nickname = fullName?.givenName ?? fullName?.familyName ?? "新草"

        do {
            // 3. 建立 Firebase Apple 憑證（官方建議寫法） // 修改内容
            let firebaseCredential = OAuthProvider.appleCredential(  // 修改内容
                withIDToken: idTokenString,  // 修改内容
                rawNonce: nonce,  // 修改内容
                fullName: credential.fullName  // 修改内容
            )

            // 4. 使用 Firebase Auth 登入
            let result = try await Auth.auth().signIn(with: firebaseCredential)

            // 5. 把使用者資料寫入 / 更新 Firestore（使用 FirestoreManager）
            let firestore = FirestoreManager.shared.db
            let userRef = firestore.collection("users").document(result.user.uid)

            let userDoc = try await userRef.getDocument()
            if !userDoc.exists {
                try await userRef.setData([
                    "id": result.user.uid,
                    "nickname": nickname,
                    "email": credential.email ?? "",
                    "createdAt": Timestamp(date: Date()),
                ])
            } else {
                if let data = userDoc.data(), data["nickname"] == nil {
                    try await userRef.updateData(["nickname": nickname])
                }
            }

            // 6. 更新本地狀態（@MainActor 確保在主線程）
            await loadUserFromFirebase(firebaseUser: result.user)
        } catch {
            print("Firebase Apple 登入失敗: \(error.localizedDescription)")
            // Firebase 失敗時，不允許進入主畫面
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first(where: { $0.isKeyWindow })
            else {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                    let window = windowScene.windows.first
                {
                    return window
                }
                return UIWindow()
            }
            return window
        #else
            return ASPresentationAnchor()
        #endif
    }
}
