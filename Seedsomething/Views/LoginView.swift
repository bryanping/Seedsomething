//
//  LoginView.swift
//  Seedsomething
//
//  Created by 林平 on 2025/11/22.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showEmailLogin = false
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var nickname = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showLoginContent = false // 控制登录内容显示
    
    var body: some View {
        ZStack {
            // 背景动画（小芽在 GeometryReader 中定位）
            SproutAnimationView(isAnimationFinished: $showLoginContent)
                .ignoresSafeArea()
            
            // 登录内容（动画结束后显示）
            if showLoginContent {
                VStack {
                    Spacer()
                    
                    // Logo 文字区域（下移以避开小芽）
                    VStack(spacing: 10) {
                        Text("種點什麼")
                            .font(.custom("PingFang TC", size: 32))
                            .fontWeight(.medium)
                            .foregroundColor(.brandDarkGray)
                        
                        Text("讓生活發芽")
                            .font(.custom("PingFang TC", size: 18))
                            .foregroundColor(.brandDarkGreen)
                        
                        Text("Grow something every day")
                            .font(.custom("PingFang TC", size: 14))
                            .foregroundColor(.brandDarkGray.opacity(0.7))
                            .padding(.top, 5)
                    }
                    .padding(.top, -150) // 增加顶部间距，避开屏幕上方的小芽
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    
                    Spacer()
                    
                    if showEmailLogin {
                        // 邮箱密码登录表单
                        emailLoginForm
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .padding(.horizontal, 40)
                    } else {
                        // 登入按鈕
                        loginButtons
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                        .frame(height: 80) // 底部留白，让按钮位置更靠下
                }
                // 使用淡入动画显示登录内容
                .transition(.opacity)
            }
        }
        .alert("錯誤", isPresented: $showError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // 登录按钮区域
    private var loginButtons: some View {
        VStack(spacing: 15) {
            // 邮箱密码登录按钮
            Button(action: {
                withAnimation {
                    showEmailLogin = true
                    isSignUp = false
                }
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("使用邮箱登入")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundColor(.brandDarkGray)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brandGrayGreen, lineWidth: 1)
                )
            }
            
            // Apple 登录
            // 使用 SignInWithAppleButton，它会自动处理授权流程
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
                // 生成 nonce 并设置到 request（用于 Firebase 验证）
                let nonce = authManager.generateNonce()
                request.nonce = authManager.sha256(nonce)
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    // 将授权结果传递给 AuthManager 处理
                    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        Task {
                            await authManager.handleAppleSignInResult(credential: appleIDCredential)
                        }
                    }
                case .failure(let error):
                    // 错误 1001 通常表示用户取消或配置问题
                    let errorDescription: String
                    if let authError = error as? ASAuthorizationError {
                        switch authError.code {
                        case .canceled:
                            errorDescription = "用户取消了登录"
                        case .failed:
                            errorDescription = "授权失败，请重试"
                        case .invalidResponse:
                            errorDescription = "无效的响应"
                        case .notHandled:
                            errorDescription = "请求未处理"
                        case .unknown:
                            errorDescription = "未知错误"
                        @unknown default:
                            errorDescription = "登录失败：\(error.localizedDescription)"
                        }
                    } else {
                        errorDescription = "登录失败：\(error.localizedDescription)"
                    }
                    errorMessage = errorDescription
                    showError = true
                }
            }
            .frame(height: 50)
            .cornerRadius(12)
            
            // Google 登录（暂时使用匿名登录）
            Button(action: {
                authManager.signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "globe")
                    Text("使用 Google 登入")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundColor(.brandDarkGray)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brandGrayGreen, lineWidth: 1)
                )
            }
        }
    }
    
    // 邮箱密码登录表单
    private var emailLoginForm: some View {
        VStack(spacing: 20) {
            // 标题
            Text(isSignUp ? "註冊帳號" : "登入")
                .font(.custom("PingFang TC", size: 24))
                .fontWeight(.medium)
                .foregroundColor(.brandDarkGray)
            
            // 表单字段
            VStack(spacing: 15) {
                // 如果是注册，显示昵称字段
                if isSignUp {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("暱稱")
                            .font(.custom("PingFang TC", size: 14))
                            .foregroundColor(.brandDarkGray)
                        TextField("請輸入暱稱", text: $nickname)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }
                }
                
                // 邮箱
                VStack(alignment: .leading, spacing: 5) {
                    Text("電子郵件")
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGray)
                    TextField("請輸入電子郵件", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // 密码
                VStack(alignment: .leading, spacing: 5) {
                    Text("密碼")
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGray)
                    SecureField("請輸入密碼", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // 操作按钮
            VStack(spacing: 12) {
                // 登录/注册按钮
                Button(action: {
                    handleEmailAuth()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isSignUp ? "註冊" : "登入")
                            .font(.custom("PingFang TC", size: 16))
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isLoading ? Color.gray : Color.brandLightGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && nickname.isEmpty))
                
                // 切换登录/注册
                Button(action: {
                    withAnimation {
                        isSignUp.toggle()
                        errorMessage = ""
                    }
                }) {
                    Text(isSignUp ? "已有帳號？點此登入" : "還沒有帳號？點此註冊")
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGreen)
                }
                
                // 忘记密码（仅登录时显示）
                if !isSignUp {
                    Button(action: {
                        handleResetPassword()
                    }) {
                        Text("忘記密碼？")
                            .font(.custom("PingFang TC", size: 14))
                            .foregroundColor(.brandDarkGray.opacity(0.7))
                    }
                }
                
                // 返回按钮
                Button(action: {
                    withAnimation {
                        showEmailLogin = false
                        email = ""
                        password = ""
                        nickname = ""
                        errorMessage = ""
                    }
                }) {
                    Text("返回")
                        .font(.custom("PingFang TC", size: 14))
                        .foregroundColor(.brandDarkGray.opacity(0.7))
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
    }
    
    // 处理邮箱认证
    private func handleEmailAuth() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "請填寫所有欄位"
            showError = true
            return
        }
        
        if isSignUp && nickname.isEmpty {
            errorMessage = "請輸入暱稱"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUpWithEmail(email: email, password: password, nickname: nickname)
                } else {
                    try await authManager.signInWithEmail(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    // 处理重置密码
    private func handleResetPassword() {
        guard !email.isEmpty else {
            errorMessage = "請先輸入電子郵件地址"
            showError = true
            return
        }
        
        Task {
            do {
                try await authManager.resetPassword(email: email)
                await MainActor.run {
                    errorMessage = "密碼重置郵件已發送到您的電子郵件"
                    showError = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}



#Preview {
    LoginView()
}
