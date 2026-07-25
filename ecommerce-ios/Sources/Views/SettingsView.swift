import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: LoginView
    @AppStorage("push_notifications_enabled") private var pushNotificationsEnabled = true
    @AppStorage("sms_notifications_enabled") private var smsNotificationsEnabled = false
    @State private var showProfileInfo = false
    @State private var showNotifications = false
    @State private var selectedDetail: SettingsDetail?
    @State private var showLogoutConfirm = false
    @State private var settingsMessage: String?


    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Section 1: Account
                    section1

                    Spacer().frame(height: 10)

                    // Section 2: General
                    section2

                    Spacer().frame(height: 10)

                    // Section 3: Notifications
                    section3

                    Spacer().frame(height: 20)

                    // Logout Button
                    logoutButton

                    // Version
                    versionText
                }
                .padding(.top, 8)
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .navigationDestination(isPresented: $showProfileInfo) {
            ProfileInfoView()
        }
        .navigationDestination(isPresented: $showNotifications) {
            NotificationsView()
        }
        .navigationDestination(item: $selectedDetail) { detail in
            SettingsDetailView(detail: detail)
        }
        .confirmationDialog("退出登录", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("退出登录", role: .destructive) {
                authManager.logout()
                dismiss()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("退出后本机登录状态会被清除。")
        }
        .alert("提示", isPresented: Binding(
            get: { settingsMessage != nil },
            set: { if !$0 { settingsMessage = nil } }
        )) {
            Button("知道了", role: .cancel) { settingsMessage = nil }
        } message: {
            Text(settingsMessage ?? "")
        }
    }

    // MARK: - Section 1: Account
    private var section1: some View {
        VStack(spacing: 0) {
            settingsItemRow(icon: "person.fill", title: "个人资料") { showProfileInfo = true }
            settingsItemRow(icon: "lock.fill", title: "账号安全") { selectedDetail = .accountSecurity }
            settingsItemRow(icon: "bell.fill", title: "消息通知", valueText: "接收") { showNotifications = true }
        }
        .background(Color.white)
    }

    // MARK: - Section 2: General
    private var section2: some View {
        VStack(spacing: 0) {
            settingsItemRow(icon: "gear", title: "通用设置") { selectedDetail = .general }
            settingsItemRow(icon: "info.circle", title: "关于我们") { selectedDetail = .about }
            settingsItemRow(icon: "questionmark.circle", title: "帮助与反馈") { selectedDetail = .help }
        }
        .background(Color.white)
    }

    // MARK: - Section 3: Notifications
    private var section3: some View {
        VStack(spacing: 0) {
            toggleSettingsRow(icon: "bell.fill", title: "推送通知", isOn: $pushNotificationsEnabled)
            toggleSettingsRow(icon: "envelope.fill", title: "短信通知", isOn: $smsNotificationsEnabled)
            settingsItemRow(icon: "person.2.fill", title: "第三方账号") { selectedDetail = .thirdParty }
        }
        .background(Color.white)
    }

    // MARK: - Settings Item Row
    private func settingsItemRow(icon: String, title: String, valueText: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.secondaryLabel))
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(.label))

                Spacer()

                if let valueText = valueText {
                    Text(valueText)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toggle Settings Row
    private func toggleSettingsRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(.secondaryLabel))
                .frame(width: 24, height: 24)

            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Color(.label))

            Spacer()

            Toggle("", isOn: isOn)
                .tint(DesignSystem.Colors.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: { showLogoutConfirm = true }) {
            Text("退出登录")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
        }
    }

    // MARK: - Version Text
    private var versionText: some View {
        Text("潮流好物 v1.0.0")
            .font(.system(size: 12))
            .foregroundStyle(Color(.systemGray3))
            .padding(.top, 10)
    }
}

private enum SettingsDetail: String, Identifiable {
    case accountSecurity
    case general
    case about
    case help
    case thirdParty

    var id: String { rawValue }

    var title: String {
        switch self {
        case .accountSecurity: return "账号安全"
        case .general: return "通用设置"
        case .about: return "关于我们"
        case .help: return "帮助与反馈"
        case .thirdParty: return "第三方账号"
        }
    }

    var rows: [(icon: String, title: String, detail: String)] {
        switch self {
        case .accountSecurity:
            return [
                ("checkmark.shield", "登录保护", "已开启本机 Token 登录校验"),
                ("lock.rotation", "密码安全", "建议定期修改密码"),
                ("iphone", "当前设备", "iOS 模拟器 / 本机调试环境")
            ]
        case .general:
            return [
                ("paintbrush", "主题模式", "跟随系统"),
                ("globe", "语言", "简体中文"),
                ("trash", "缓存", "图片和接口缓存由系统自动管理")
            ]
        case .about:
            return [
                ("bag", "潮流好物", "年轻人的购物主场"),
                ("number", "版本", "1.0.0"),
                ("doc.text", "服务说明", "购物车、订单、收藏、会员与通知流程已接入本地 API")
            ]
        case .help:
            return [
                ("message", "在线客服", "工作日 09:00-21:00"),
                ("arrow.uturn.left", "售后规则", "订单详情页可提交售后申请"),
                ("exclamationmark.bubble", "反馈入口", "问题会记录到本地演示流程")
            ]
        case .thirdParty:
            return [
                ("person.2", "微信", "暂未绑定"),
                ("creditcard", "支付宝", "暂未绑定"),
                ("apple.logo", "Apple", "暂未绑定")
            ]
        }
    }
}

private struct SettingsDetailView: View {
    let detail: SettingsDetail

    var body: some View {
        List {
            ForEach(detail.rows, id: \.title) { row in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: row.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.accent)
                        .frame(width: 28, height: 28)
                        .background(DesignSystem.Colors.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.title)
                            .font(.system(size: 15, weight: .semibold))
                        Text(row.detail)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(detail.title)
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(LoginView.shared)
}
