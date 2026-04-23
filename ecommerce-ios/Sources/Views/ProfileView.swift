import SwiftUI

struct ProfileView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                userHeader
                memberBanner
                profileBody
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - User Header
    private var userHeader: some View {
        NavigationLink(destination: ProfileInfoView()) {
            ZStack(alignment: .topLeading) {
                // Gradient Background
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.42, blue: 0.29),
                        Color(red: 1.0, green: 0.54, blue: 0.42),
                        Color(red: 1.0, green: 0.67, blue: 0.53)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)

                // Decorative circles
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .offset(x: 100, y: -30)

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 160, height: 160)
                    .offset(x: -20, y: 80)

                // User Card
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        // Avatar
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 68, height: 68)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundStyle(.white.opacity(0.8))
                                )

                            // Level Badge
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 22, height: 22)

                                Text("6")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 4, y: 4)
                        }

                        // User Info
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("林小琳")
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundStyle(.white)

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }

                            Text("ID: 88888888")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))

                            HStack(spacing: 20) {
                                UserStat(number: "128", label: "关注")
                                UserStat(number: "356", label: "粉丝")
                                UserStat(number: "2,860", label: "积分")
                            }
                        }

                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 80)
                .padding(.bottom, 24)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Member Banner
    private var memberBanner: some View {
        NavigationLink(destination: VIPView()) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Crown Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)

                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("黄金会员")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)

                    Text("有效期至 2027.03")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))

                    Text("每月领取专属优惠券包 · 专享价商品 · 生日礼包")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Button(action: {}) {
                    Text("续费")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.1), Color(red: 0.18, green: 0.18, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.top, -12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Profile Body
    private var profileBody: some View {
        VStack(spacing: 12) {
            // Orders Card
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("我的订单")
                        .font(.system(size: 16, weight: .bold))

                    Spacer()

                    NavigationLink(destination: OrderView()) {
                        HStack(spacing: 2) {
                            Text("全部订单")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.gray)
                        }
                    }
                }

                HStack(spacing: 0) {
                    OrderItem(icon: "clock", label: "待付款", badge: nil, destination: .pending)
                    OrderItem(icon: "shippingbox", label: "待发货", badge: "1", destination: .paid)
                    OrderItem(icon: "shippingbox.fill", label: "待收货", badge: nil, destination: .shipped)
                    OrderItem(icon: "message", label: "待评价", badge: nil, destination: .completed)
                    OrderItem(icon: "arrow.uturn.left", label: "退款/售后", badge: nil, destination: .all)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Assets Grid
            NavigationLink(destination: CouponView()) {
                HStack(spacing: 0) {
                    AssetItem(number: "4", label: "优惠券")
                    AssetItem(number: "0", label: "积分")
                    AssetItem(number: "0", label: "红包")
                    AssetItem(number: "0", label: "礼品卡")
                }
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            // Service Card
            VStack(alignment: .leading, spacing: 14) {
                Text("常用服务")
                    .font(.system(size: 16, weight: .bold))

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    NavigationLink(destination: FavoritesView()) {
                        ServiceItem(icon: "heart.fill", label: "我的收藏", iconColor: Color(red: 0.9, green: 0.4, blue: 0.0), iconBg: Color(red: 1.0, green: 0.95, blue: 0.88))
                    }
                    NavigationLink(destination: HistoryView()) {
                        ServiceItem(icon: "clock", label: "浏览足迹", iconColor: Color(red: 0.08, green: 0.4, blue: 0.75), iconBg: Color(red: 0.89, green: 0.95, blue: 0.99))
                    }
                    NavigationLink(destination: AddressView()) {
                        ServiceItem(icon: "location", label: "地址管理", iconColor: Color(red: 0.49, green: 0.3, blue: 1.0), iconBg: Color(red: 0.95, green: 0.9, blue: 0.96))
                    }
                    NavigationLink(destination: NotificationsView()) {
                        ServiceItem(icon: "bell", label: "消息通知", iconColor: Color(red: 0.91, green: 0.12, blue: 0.39), iconBg: Color(red: 1.0, green: 0.92, blue: 0.93))
                    }
                    NavigationLink(destination: SettingsView()) {
                        ServiceItem(icon: "gearshape", label: "设置", iconColor: Color(red: 0.0, green: 0.54, blue: 0.48), iconBg: Color(red: 0.88, green: 0.95, blue: 0.95))
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Invite Banner
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("邀请好友赚佣金")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text("每成功邀请1位好友获得20元优惠券")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Button(action: {}) {
                    Text("立即邀请")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.1), Color(red: 0.18, green: 0.18, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .padding(.top, 12)
    }
}

// MARK: - User Stat
struct UserStat: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 1) {
            Text(number)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

// MARK: - Order Item
struct OrderItem: View {
    let icon: String
    let label: String
    let badge: String?
    let destination: OrderStatus

    var body: some View {
        NavigationLink(destination: OrderView(initialStatus: destination)) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.96, blue: 0.95))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .background(DesignSystem.Colors.accent)
                            .clipShape(Capsule())
                            .offset(x: 14, y: -10)
                    }
                }

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(.darkGray))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Asset Item
struct AssetItem: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(number)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.29))

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(.darkGray))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Service Item
struct ServiceItem: View {
    let icon: String
    let label: String
    let iconColor: Color
    let iconBg: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBg)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
            }

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(.darkGray))
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(Cart())
}
