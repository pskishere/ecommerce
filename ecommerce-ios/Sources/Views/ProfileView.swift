import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authManager: LoginView
    @State private var user: User?
    @State private var isLoading = true
    @State private var orderCounts: [OrderStatus: Int] = [:]
    @State private var couponCount = 0
    @State private var toast: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                userHeader
                memberBanner
                profileBody
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .ignoresSafeArea(edges: .top)
        .toast($toast, bottomPadding: 96)
        .task {
            await loadProfile()
        }
    }

    // MARK: - User Header
    private var userHeader: some View {
        NavigationLink(destination: ProfileInfoView()) {
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.accent,
                        Color(red: 1.0, green: 0.54, blue: 0.42),
                        Color(red: 1.0, green: 0.67, blue: 0.53)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .offset(x: 100, y: -30)

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 160, height: 160)
                    .offset(x: -20, y: 80)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 68, height: 68)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundStyle(.white.opacity(0.8))
                                )

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

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(user?.name ?? "未登录")
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundStyle(.white)

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }

                            Text("ID: \(user?.id ?? 0)")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))

                            HStack(spacing: 20) {
                                UserStat(number: "\(user?.followCount ?? 0)", label: "关注")
                                UserStat(number: "\(user?.fansCount ?? 0)", label: "粉丝")
                                UserStat(number: "\(user?.points ?? 0)", label: "积分")
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

    private func loadProfile() async {
        async let userTask = User.getProfile()
        async let ordersTask = Order.getList()
        async let couponsTask = UserCoupon.getCoupons()
        do {
            user = try await userTask
        } catch {
            toast = userFacingErrorMessage(error, fallback: "个人资料加载失败")
        }
        do {
            let orders = try await ordersTask
            var counts: [OrderStatus: Int] = [:]
            for o in orders { counts[o.status, default: 0] += 1 }
            orderCounts = counts
        } catch {
            toast = userFacingErrorMessage(error, fallback: "订单统计加载失败")
        }
        do {
            let coupons = try await couponsTask
            couponCount = coupons.filter { $0.status == "available" }.count
        } catch {
            toast = userFacingErrorMessage(error, fallback: "优惠券统计加载失败")
        }
        isLoading = false
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
                    Text(user?.vipLevelName ?? "普通会员")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)

                    if let expire = user?.vipExpireDate {
                        Text("有效期至 \(expire.prefix(7).replacingOccurrences(of: "-", with: "."))")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text("开通会员享受专属权益")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Text("专享优惠券 · 积分加倍 · 免运费")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Text(user?.vipLevel == "none" ? "立即开通" : "续费")
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
                    OrderItem(icon: "clock", label: "待付款", badge: orderCounts[.pending].map { $0 > 0 ? "\($0)" : nil } ?? nil, destination: .pending)
                    OrderItem(icon: "shippingbox", label: "待发货", badge: orderCounts[.paid].map { $0 > 0 ? "\($0)" : nil } ?? nil, destination: .paid)
                    OrderItem(icon: "shippingbox.fill", label: "待收货", badge: orderCounts[.shipped].map { $0 > 0 ? "\($0)" : nil } ?? nil, destination: .shipped)
                    OrderItem(icon: "message", label: "待评价", badge: orderCounts[.completed].map { $0 > 0 ? "\($0)" : nil } ?? nil, destination: .completed)
                    OrderItem(icon: "arrow.uturn.left", label: "退款/售后", badge: nil, destination: .all)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Assets Grid
            NavigationLink(destination: CouponView()) {
                HStack(spacing: 0) {
                    AssetItem(number: "\(couponCount)", label: "优惠券")
                    AssetItem(number: "\(user?.points ?? 0)", label: "积分")
                    AssetItem(number: "0", label: "红包")
                    AssetItem(number: "0", label: "礼品卡")
                }
                .padding(.vertical, 14)
                .background(DesignSystem.Colors.secondaryBackground)
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

                ShareLink(item: inviteURL) {
                    Text("立即邀请")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
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

    private var inviteURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:5173/index.html")!
        #else
        return URL(string: "https://handsome-youth-production-98c5.up.railway.app/index.html")!
        #endif
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
                .foregroundStyle(DesignSystem.Colors.accent)

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
