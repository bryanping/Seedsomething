//
//  AuthManager.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import Foundation
import SwiftUI
import AuthenticationServices
import UIKit

class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private override init() {
        super.init()
        // 從本地儲存載入使用者資料
        loadUser()
    }
    
    // Apple Sign In
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // Google Sign In (需要額外配置)
    func signInWithGoogle() {
        // TODO: 實現 Google Sign In
        // 暫時使用模擬登入
        let mockUser = User(nickname: "測試草")
        currentUser = mockUser
        isAuthenticated = true
        saveUser()
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    private func saveUser() {
        if let user = currentUser, let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    private func loadUser() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            let nickname = fullName?.givenName ?? fullName?.familyName ?? "新草"
            let user = User(id: userIdentifier, nickname: nickname)
            
            currentUser = user
            isAuthenticated = true
            saveUser()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In 錯誤: \(error.localizedDescription)")
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // 如果找不到 key window，尝试返回第一个窗口
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                return window
            }
            // 最后的回退方案：创建一个新的窗口（这通常不会发生）
            return UIWindow()
        }
        return window
    }
}

