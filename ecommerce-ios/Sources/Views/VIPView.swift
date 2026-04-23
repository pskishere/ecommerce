import SwiftUI

struct VIPView: View {
    @StateObject private var viewModel = VIPViewModel()

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Member Stats
                memberStatsSection

                // Privileges
                privilegesSection

                // Benefits
                benefitsSection

                // Upgrade Button
                upgradeButton
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("会员中心")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
    }

    // MARK: - Header Section
    private var headerSection: some View {
        ZStack(alignment: .topLeading) {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.1),
                    Color(red: 0.18, green: 0.18, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 200, height: 200)
                .offset(x: 200, y: -50)

            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 150, height: 150)
                .offset(x: -30, y: 100)

            // Content
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 70, height: 70)

                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("林小琳")
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(.white)

                            // Crown
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.yellow)
                        }

                        Text("黄金会员")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    // Member since
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("会员到期")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("2027.03.15")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("距离钻石会员还差")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))

                        Text("¥2,140")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.yellow)

                        Text("累计消费")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * 0.65, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Member Stats Section
    private var memberStatsSection: some View {
        HStack(spacing: 0) {
            statItem(value: "¥860", label: "累计消费")
            statItem(value: "12", label: "优惠券")
            statItem(value: "2,860", label: "积分")
            statItem(value: "VIP 6", label: "成长等级")
        }
        .padding(.vertical, 16)
        .background(Color.white)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(accentColor)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Privileges Section
    private var privilegesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("会员特权")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: {}) {
                    HStack(spacing: 2) {
                        Text("查看全部")
                            .font(.system(size: 12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.privileges, id: \.title) { privilege in
                        privilegeCard(privilege)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .background(Color.white)
    }

    private func privilegeCard(_ privilege: VIPPrivilege) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(privilege.color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: privilege.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(privilege.color)
            }

            Text(privilege.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)

            Text(privilege.desc)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
    }

    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("我的权益")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
                .padding(16)

            VStack(spacing: 0) {
                ForEach(viewModel.benefits, id: \.title) { benefit in
                    benefitRow(benefit)

                    if benefit.id != viewModel.benefits.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color.white)
        }
    }

    private func benefitRow(_ benefit: VIPBenefit) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(benefit.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: benefit.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(benefit.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(benefit.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                Text(benefit.desc)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if benefit.isNew {
                Text("NEW")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor)
                    .clipShape(Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    // MARK: - Upgrade Button
    private var upgradeButton: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))

                Text("升级为钻石会员")
                    .font(.system(size: 16, weight: .bold))

                Text("立享8大专属权益")
                    .font(.system(size: 12))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(16)
        }
    }
}

// MARK: - VIP Privilege
struct VIPPrivilege {
    let title: String
    let desc: String
    let icon: String
    let color: Color
}

// MARK: - VIP Benefit
struct VIPBenefit: Identifiable {
    let id: UUID
    let title: String
    let desc: String
    let icon: String
    let color: Color
    let isNew: Bool
}

// MARK: - VIP ViewModel
class VIPViewModel: ObservableObject {
    let privileges: [VIPPrivilege] = [
        VIPPrivilege(title: "专享价", desc: "会员专属折扣", icon: "tag.fill", color: .red),
        VIPPrivilege(title: "生日礼", desc: "生日礼包", icon: "gift.fill", color: .orange),
        VIPPrivilege(title: "专属客服", desc: "优先客服", icon: "headphones", color: .blue),
        VIPPrivilege(title: "免运费", desc: "每月免运费券", icon: "shippingbox.fill", color: .green),
        VIPPrivilege(title: "积分加倍", desc: "购物积分翻倍", icon: "star.fill", color: .yellow),
        VIPPrivilege(title: "会员日", desc: "每月会员日", icon: "calendar", color: .purple)
    ]

    let benefits: [VIPBenefit] = [
        VIPBenefit(id: UUID(), title: "专享折扣", desc: "全场商品享受黄金会员专属价", icon: "percent", color: .red, isNew: false),
        VIPBenefit(id: UUID(), title: "每月优惠券包", desc: "每月领取消平台优惠券（价值100元+）", icon: "ticket.fill", color: .orange, isNew: true),
        VIPBenefit(id: UUID(), title: "生日礼包", desc: "生日当月领取专属礼包", icon: "gift.fill", color: .purple, isNew: false),
        VIPBenefit(id: UUID(), title: "专属客服", desc: "7x24小时优先客服接入", icon: "headphones", color: .blue, isNew: false),
        VIPBenefit(id: UUID(), title: "免运费券", desc: "每月赠送3张免运费券", icon: "shippingbox.fill", color: .green, isNew: true),
        VIPBenefit(id: UUID(), title: "积分翻倍", desc: "购物享受积分双倍累计", icon: "star.fill", color: .yellow, isNew: false)
    ]
}

#Preview {
    NavigationStack {
        VIPView()
    }
}
