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
    @State private var password = "iole"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var legalDocument: LegalDocument?
    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case password
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LoginBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        LoginBrandHeader()

                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("账号登录")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(LoginPalette.ink)

                                Text("潮流好物")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(LoginPalette.muted)
                            }

                            loginField(
                                title: "用户名",
                                systemImage: "person",
                                isFocused: focusedField == .username
                            ) {
                                TextField("请输入用户名", text: $username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .submitLabel(.next)
                                    .focused($focusedField, equals: .username)
                                    .onSubmit { focusedField = .password }
                            }

                            loginField(
                                title: "密码",
                                systemImage: "lock",
                                isFocused: focusedField == .password
                            ) {
                                SecureField("请输入密码", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .submitLabel(.go)
                                    .focused($focusedField, equals: .password)
                                    .onSubmit { performLogin() }
                            }

                            if showError, let msg = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text(msg)
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(LoginPalette.error)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(LoginPalette.error.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            Button(action: performLogin) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("登录")
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(isLoginDisabled ? LoginPalette.disabled : LoginPalette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(
                                    color: isLoginDisabled ? .clear : LoginPalette.accent.opacity(0.26),
                                    radius: 14,
                                    x: 0,
                                    y: 10
                                )
                            }
                            .buttonStyle(TactileButtonStyle())
                            .disabled(isLoginDisabled)
                            .padding(.top, 4)

                            agreementText
                                .frame(maxWidth: .infinity)
                        }
                        .padding(24)
                        .background(.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.8), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, max(28, proxy.safeAreaInsets.top + 18))
                    .padding(.bottom, max(32, proxy.safeAreaInsets.bottom + 24))
                    .frame(minHeight: proxy.size.height, alignment: .center)
                }
            }
            .sheet(item: $legalDocument) { document in
                LegalDocumentView(document: document)
            }
        }
    }

    private var isLoginDisabled: Bool {
        isLoading || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty
    }

    private var agreementText: some View {
        HStack(spacing: 4) {
            Text("登录即表示同意")
                .foregroundStyle(LoginPalette.muted)
            Button(action: { legalDocument = .userAgreement }) {
                Text("《用户协议》")
                    .foregroundStyle(LoginPalette.accent)
            }
            Text("和")
                .foregroundStyle(LoginPalette.muted)
            Button(action: { legalDocument = .privacyPolicy }) {
                Text("《隐私政策》")
                    .foregroundStyle(LoginPalette.accent)
            }
        }
        .font(.system(size: 12, weight: .medium))
    }

    private func loginField<Content: View>(
        title: String,
        systemImage: String,
        isFocused: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isFocused ? LoginPalette.accent : LoginPalette.muted)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LoginPalette.muted)

                content()
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(LoginPalette.ink)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 66)
        .background(LoginPalette.field)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isFocused ? LoginPalette.accent.opacity(0.65) : LoginPalette.line, lineWidth: isFocused ? 1.5 : 1)
        )
    }

    private func performLogin() {
        guard !isLoginDisabled else { return }
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

private enum LegalDocument: String, Identifiable {
    case userAgreement
    case privacyPolicy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .userAgreement:
            return "用户协议"
        case .privacyPolicy:
            return "隐私政策"
        }
    }

    var body: String {
        switch self {
        case .userAgreement:
            return "欢迎使用潮流好物。登录后你可以同步购物车、订单、收藏、优惠券和会员权益。请妥善保管账号信息，不要使用本服务从事违法违规交易。订单、支付、售后与通知功能会根据你的操作在服务端保存必要记录，以便完成商城业务流程。"
        case .privacyPolicy:
            return "潮流好物只在完成账号登录、收货地址、订单履约、购物车同步、头像更新和通知提醒等必要场景下处理你的信息。你可以在个人资料、地址管理、通知和设置页面查看或修改相关内容。退出登录后，本机认证状态会被清除。"
        }
    }
}

private struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(document.body)
                    .font(.system(size: 15))
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .lineSpacing(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
        }
    }
}

private enum LoginPalette {
    static let canvas = Color(red: 0.965, green: 0.976, blue: 0.966)
    static let shelf = Color(red: 0.925, green: 0.950, blue: 0.930)
    static let warmSurface = Color(red: 1.000, green: 0.965, blue: 0.945)
    static let field = Color(red: 0.985, green: 0.985, blue: 0.975)
    static let line = Color.black.opacity(0.08)
    static let ink = Color(red: 0.105, green: 0.125, blue: 0.115)
    static let muted = Color(red: 0.450, green: 0.490, blue: 0.465)
    static let accent = DesignSystem.Colors.accent
    static let disabled = Color(red: 0.780, green: 0.800, blue: 0.780)
    static let error = Color(red: 0.820, green: 0.180, blue: 0.140)
}

private struct LoginBackground: View {
    var body: some View {
        ZStack(alignment: .top) {
            LoginPalette.canvas

            VStack(spacing: 0) {
                LoginPalette.shelf
                    .frame(height: 285)
                Spacer()
                LoginPalette.warmSurface
                    .frame(height: 210)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 44,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                    )
            }
            .ignoresSafeArea()
        }
    }
}

private struct LoginBrandHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white)
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)

                    Image(systemName: "bag")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(LoginPalette.accent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("潮流好物")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(LoginPalette.ink)

                    Text("年轻人的购物主场")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LoginPalette.muted)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                Text("登录后同步购物车、订单和会员权益")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(LoginPalette.muted)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white.opacity(0.72))
            .clipShape(Capsule())
        }
    }
}

#Preview {
    LoginFormView()
        .environmentObject(LoginView.shared)
}
