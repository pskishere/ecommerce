import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [UserNotification] = []
    @State private var selectedTab: String = "全部"
    @State private var isLoading = true

    private let accentColor = DesignSystem.Colors.accent
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
        .background(Color(.systemGroupedBackground))
        .navigationTitle("消息通知")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await markAllAsRead() } }) {
                    Text("全部已读")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .hideTabBar()
        .task {
            do {
                notifications = try await UserNotification.getNotifications()
            } catch {
                print("Failed to load notifications: \(error)")
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
            print("Failed to mark as read: \(error)")
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
        } catch {
            print("Failed to mark all as read: \(error)")
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: UserNotification
    let onTap: () -> Void

    private let accentColor = DesignSystem.Colors.accent

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
                                .fill(accentColor)
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
