import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            tabBar

            // Notification List
            if viewModel.filteredNotifications.isEmpty {
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
                Button(action: { viewModel.markAllAsRead() }) {
                    Text("全部已读")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .hideTabBar()
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        ContentTab(
            tabs: viewModel.tabs.map {
                ContentTabItem(
                    value: $0,
                    label: $0,
                    badgeCount: viewModel.unreadCounts[$0]
                )
            },
            selectedTab: $viewModel.selectedTab
        )
    }

    // MARK: - Notification List
    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredNotifications) { notification in
                    NotificationRow(notification: notification) {
                        viewModel.markAsRead(notification)
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
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(notification.type.color.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: notification.type.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(notification.type.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
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

// MARK: - App Notification
struct AppNotification: Identifiable {
    let id: UUID
    let title: String
    let content: String
    let time: String
    let type: NotificationType
    var isRead: Bool
}

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

// MARK: - Notifications ViewModel
class NotificationsViewModel: ObservableObject {
    @Published var selectedTab: String = "全部"
    @Published var notifications: [AppNotification]

    let tabs = ["全部", "订单", "优惠", "系统"]

    var unreadCounts: [String: Int] {
        [
            "全部": notifications.filter { !$0.isRead }.count,
            "订单": notifications.filter { !$0.isRead && $0.type == .order }.count,
            "优惠": notifications.filter { !$0.isRead && $0.type == .promotion }.count,
            "系统": notifications.filter { !$0.isRead && $0.type == .system }.count
        ]
    }

    var filteredNotifications: [AppNotification] {
        switch selectedTab {
        case "全部":
            return notifications
        case "订单":
            return notifications.filter { $0.type == .order }
        case "优惠":
            return notifications.filter { $0.type == .promotion }
        case "系统":
            return notifications.filter { $0.type == .system }
        default:
            return notifications
        }
    }

    init() {
        notifications = [
            AppNotification(id: UUID(), title: "订单已发货", content: "您的订单已于今日发货，快递单号：SF1234567890，请注意查收", time: "刚刚", type: .order, isRead: false),
            AppNotification(id: UUID(), title: "优惠券到账", content: "您有一张满99减20的优惠券已到账，有效期7天", time: "10分钟前", type: .promotion, isRead: false),
            AppNotification(id: UUID(), title: "限时折扣", content: "春季新品上市，全场低至5折起", time: "1小时前", type: .promotion, isRead: true),
            AppNotification(id: UUID(), title: "订单已签收", content: "您的订单已完成签收，如有问题可随时联系客服", time: "今天 12:30", type: .order, isRead: true),
            AppNotification(id: UUID(), title: "系统更新", content: "App已更新至最新版本，体验更流畅", time: "昨天", type: .system, isRead: true)
        ]
    }

    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }

    func markAllAsRead() {
        notifications = notifications.map { notification in
            AppNotification(
                id: notification.id,
                title: notification.title,
                content: notification.content,
                time: notification.time,
                type: notification.type,
                isRead: true
            )
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
