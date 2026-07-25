import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [UserNotification] = []
    @State private var selectedTab: String = "全部"
    @State private var isLoading = true
    @State private var selectedNotification: UserNotification?
    @State private var toast: String? = nil

    private let tabs = ["全部", "订单", "优惠", "系统"]

    private var filteredNotifications: [UserNotification] {
        switch selectedTab {
        case "全部":
            return notifications
        case "订单":
            return notifications.filter { $0.type == "logistics" || $0.type == "order" }
        case "优惠":
            return notifications.filter { $0.type == "promo" }
        case "系统":
            return notifications.filter { $0.type == "sys" }
        default:
            return notifications
        }
    }

    private var unreadCounts: [String: Int] {
        [
            "全部": notifications.filter { !$0.isRead }.count,
            "订单": notifications.filter { !$0.isRead && ($0.type == "logistics" || $0.type == "order") }.count,
            "优惠": notifications.filter { !$0.isRead && $0.type == "promo" }.count,
            "系统": notifications.filter { !$0.isRead && $0.type == "sys" }.count
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredNotifications.isEmpty {
                emptyView
            } else {
                notificationList
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle("消息通知")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await markAllAsRead() } }) {
                    Text("全部已读")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
        }
        .hideTabBar()
        .toast($toast, bottomPadding: 80)
        .sheet(item: $selectedNotification) { notification in
            NotificationDetailSheet(notification: notification)
        }
        .task {
            do {
                notifications = try await UserNotification.getNotifications()
            } catch {
                toast = userFacingErrorMessage(error, fallback: "消息加载失败")
            }
            isLoading = false
        }
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        ContentTab(
            tabs: tabs.map {
                ContentTabItem(
                    value: $0,
                    label: $0,
                    badgeCount: unreadCounts[$0]
                )
            },
            selectedTab: $selectedTab
        )
    }

    // MARK: - Notification List
    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredNotifications) { notification in
                    NotificationRow(notification: notification) {
                        selectedNotification = notification
                        Task { await markAsRead(notification) }
                    }
                    Divider()
                        .padding(.leading, 60)
                }
            }
            .background(Color.white)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color(.tertiaryLabel))

            Text("暂无消息")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func markAsRead(_ notification: UserNotification) async {
        do {
            try await UserNotification.markRead(id: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = UserNotification(
                    id: notification.id,
                    type: notification.type,
                    name: notification.name,
                    time: notification.time,
                    content: notification.content,
                    action: notification.action,
                    isRead: true
                )
            }
        } catch {
            toast = userFacingErrorMessage(error, fallback: "已读操作失败")
        }
    }

    private func markAllAsRead() async {
        do {
            try await UserNotification.markAllRead()
            notifications = notifications.map {
                UserNotification(
                    id: $0.id,
                    type: $0.type,
                    name: $0.name,
                    time: $0.time,
                    content: $0.content,
                    action: $0.action,
                    isRead: true
                )
            }
            toast = "已全部标为已读"
        } catch {
            toast = userFacingErrorMessage(error, fallback: "全部已读失败")
        }
    }
}

private struct NotificationDetailSheet: View {
    let notification: UserNotification
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appNavigation: AppNavigation

    private var notificationType: NotificationType {
        switch notification.type {
        case "logistics", "order": return .order
        case "promo": return .promotion
        default: return .system
        }
    }

    private var actionTitle: String {
        switch notificationType {
        case .order: return "查看订单"
        case .promotion: return "去使用"
        case .system: return "知道了"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(notificationType.color.opacity(0.12))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Image(systemName: notificationType.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(notificationType.color)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.name)
                            .font(.system(size: 17, weight: .bold))
                        Text(notification.time)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(notification.content)
                    .font(.system(size: 15))
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button(action: handleAction) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
            }
            .padding(20)
            .navigationTitle("消息详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func handleAction() {
        switch notificationType {
        case .order:
            appNavigation.selectedTab = .profile
        case .promotion:
            appNavigation.selectedTab = .cart
        case .system:
            break
        }
        dismiss()
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: UserNotification
    let onTap: () -> Void


    private var notificationType: NotificationType {
        switch notification.type {
        case "logistics", "order": return .order
        case "promo": return .promotion
        default: return .system
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(notificationType.color.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: notificationType.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(notificationType.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(DesignSystem.Colors.accent)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.content)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(notification.time)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Type
enum NotificationType {
    case order
    case promotion
    case system

    var icon: String {
        switch self {
        case .order: return "shippingbox"
        case .promotion: return "gift"
        case .system: return "bell"
        }
    }

    var color: Color {
        switch self {
        case .order: return Color.blue
        case .promotion: return Color.orange
        case .system: return Color.gray
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
