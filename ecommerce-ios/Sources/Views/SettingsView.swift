import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pushNotificationsEnabled = true
    @State private var smsNotificationsEnabled = false

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
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
        .background(Color(.systemGroupedBackground))
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
    }

    // MARK: - Section 1: Account
    private var section1: some View {
        VStack(spacing: 0) {
            settingsItemRow(icon: "person.fill", title: "个人资料") { }
            settingsItemRow(icon: "lock.fill", title: "账号安全") { }
            settingsItemRow(icon: "bell.fill", title: "消息通知", valueText: "接收") { }
        }
        .background(Color.white)
    }

    // MARK: - Section 2: General
    private var section2: some View {
        VStack(spacing: 0) {
            settingsItemRow(icon: "gear", title: "通用设置") { }
            settingsItemRow(icon: "info.circle", title: "关于我们") { }
            settingsItemRow(icon: "questionmark.circle", title: "帮助与反馈") { }
        }
        .background(Color.white)
    }

    // MARK: - Section 3: Notifications
    private var section3: some View {
        VStack(spacing: 0) {
            toggleSettingsRow(icon: "bell.fill", title: "推送通知", isOn: $pushNotificationsEnabled)
            toggleSettingsRow(icon: "envelope.fill", title: "短信通知", isOn: $smsNotificationsEnabled)
            settingsItemRow(icon: "person.2.fill", title: "第三方账号") { }
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
                .tint(accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: {}) {
            Text("退出登录")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(accentColor)
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

#Preview {
    NavigationStack {
        SettingsView()
    }
}
