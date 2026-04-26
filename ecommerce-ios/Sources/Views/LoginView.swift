import Foundation
import SwiftUI

@MainActor
final class LoginView: ObservableObject {
    static let shared = LoginView()

    @Published var isAuthenticated: Bool = false
    @Published var userType: String?

    private let tokenKey = "auth_token"
    private let userTypeKey = "auth_user_type"

    private init() {
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            self.isAuthenticated = true
            self.userType = UserDefaults.standard.string(forKey: userTypeKey)
        }
    }

    func login(token: String, userType: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(userType, forKey: userTypeKey)
        self.isAuthenticated = true
        self.userType = userType
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userTypeKey)
        APIClient.shared.logout()
        self.isAuthenticated = false
        self.userType = nil
    }
}

struct LoginFormView: View {
    @EnvironmentObject private var authManager: LoginView
    @State private var username = "testuser"
    @State private var password = "testuser"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)

                    Image(systemName: "bag")
                        .font(.system(size: 36))
                        .foregroundStyle(accentColor)
                }

                Text("潮流好物")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("年轻人的购物主场")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.top, 80)
            .padding(.bottom, 40)

            // Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("用户名")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    TextField("请输入用户名", text: $username)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("密码")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    SecureField("请输入密码", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        )
                }

                if showError, let msg = errorMessage {
                    Text(msg)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                }

                Button(action: performLogin) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("登录")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isLoading ? accentColor.opacity(0.7) : accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading || username.isEmpty || password.isEmpty)
                .padding(.top, 8)

                HStack(spacing: 4) {
                    Text("登录即表示同意")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Button(action: {}) {
                        Text("《用户协议》")
                            .font(.system(size: 12))
                            .foregroundStyle(accentColor)
                    }
                    Text("和")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Button(action: {}) {
                        Text("《隐私政策》")
                            .font(.system(size: 12))
                            .foregroundStyle(accentColor)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [accentColor, Color(red: 1.0, green: 0.54, blue: 0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func performLogin() {
        isLoading = true
        showError = false

        Task {
            do {
                let resp = try await APIClient.shared.login(username: username, password: password)
                LoginView.shared.login(token: resp.token, userType: resp.userType)
            } catch let error as APIError {
                errorMessage = error.errorDescription
                showError = true
            } catch {
                errorMessage = "登录失败"
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginFormView()
        .environmentObject(LoginView.shared)
}