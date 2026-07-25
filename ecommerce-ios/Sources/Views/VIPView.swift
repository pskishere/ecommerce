import SwiftUI

struct VIPView: View {
    @StateObject private var viewModel = VIPViewModel()
    @State private var showCoupons = false
    @State private var showShop = false


    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    benefitsSection
                    privilegesSection
                    historySection
                    upgradeButton
                }
                .padding(.bottom, 12)
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle("会员中心")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .navigationDestination(isPresented: $showCoupons) {
            CouponView()
        }
        .navigationDestination(isPresented: $showShop) {
            ShopView()
        }
        .toast($viewModel.errorMessage, bottomPadding: 80)
        .task { await viewModel.load() }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFE0D0"))
                        .frame(width: 56, height: 56)

                    Image(systemName: "person.fill")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(viewModel.user?.name ?? "会员")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.dark)

                        Image(systemName: "star")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.accent)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                        Text(viewModel.vip?.levelName ?? "普通会员")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())

                    Text(expireText)
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.gray2)
                }

                Spacer()
            }

            HStack(spacing: 0) {
                vipPointItem(value: "\(viewModel.vip?.points ?? 0)", label: "可用积分")

                Rectangle()
                    .fill(Color(hex: "F0F0F0"))
                    .frame(width: 1, height: 30)

                vipPointItem(value: "\(viewModel.vip?.growthValue ?? 0)", label: "成长值")
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFF8F0"), Color(hex: "FFF0E8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.accent.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var expireText: String {
        guard let expire = viewModel.vip?.expireDate else { return "会员有效期 - " }
        return "有效期至 \(String(expire.prefix(10)))"
    }

    private func vipPointItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.accent)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(DesignSystem.Colors.gray2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Privileges Section
    private var privilegesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.privilegeRows.enumerated()), id: \.element.title) { index, privilege in
                Button(action: { handlePrivilege(privilege) }) {
                    privilegeRow(privilege)
                }
                .buttonStyle(.plain)

                if index < viewModel.privilegeRows.count - 1 {
                    Rectangle()
                        .fill(DesignSystem.Colors.pageBackground)
                        .frame(height: 1)
                        .padding(.leading, 42)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private func handlePrivilege(_ privilege: VIPActionRow) {
        if privilege.title.contains("优惠券") {
            showCoupons = true
        } else if privilege.title.contains("商品") {
            showShop = true
        } else {
            viewModel.errorMessage = "\(privilege.title)权益已生效"
        }
    }

    private func privilegeRow(_ privilege: VIPActionRow) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.accentSoft)
                    .frame(width: 32, height: 32)

                Image(systemName: privilege.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(privilege.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.dark)

                Text(privilege.desc)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignSystem.Colors.gray2)
            }

            Spacer()

            Text(privilege.action)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.accent)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("会员专享权益")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.dark)
                .padding(.bottom, 12)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(viewModel.benefitGridItems) { benefit in
                    benefitGridItem(benefit)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private func benefitGridItem(_ benefit: VIPGridBenefit) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignSystem.Colors.accentSoft)
                    .frame(width: 36, height: 36)

                Image(systemName: benefit.icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.accent)
            }

            Text(benefit.title)
                .font(.system(size: 11))
                .foregroundStyle(DesignSystem.Colors.gray1)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("积分明细")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.dark)

            VStack(spacing: 10) {
                ForEach(viewModel.historyItems) { item in
                    historyRow(item)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private func historyRow(_ item: VIPHistoryItem) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.accentSoft)
                    .frame(width: 32, height: 32)

                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.dark)

                Text(item.time)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignSystem.Colors.gray3)
            }

            Spacer()

            Text(item.points)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(item.isNegative ? DesignSystem.Colors.gray2 : DesignSystem.Colors.accent)
        }
    }

    // MARK: - Upgrade Button
    private var upgradeButton: some View {
        Group {
            if !(viewModel.vip?.isMaxLevel ?? false) {
                Button(action: { Task { await viewModel.upgrade() } }) {
                    HStack(spacing: 8) {
                        if viewModel.isUpgrading {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "crown.fill").font(.system(size: 16))
                        }
                        let nextName = viewModel.vip?.nextLevelName ?? "VIP会员"
                        Text(viewModel.vip?.level == "none" ? "立即开通会员" : "升级为\(nextName)")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .padding(.top, 6)
                    .padding(.bottom, 20)
                }
                .disabled(viewModel.isUpgrading)
            }
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

struct VIPGridBenefit: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

struct VIPActionRow: Identifiable {
    let id = UUID()
    let title: String
    let desc: String
    let icon: String
    let action: String
}

struct VIPHistoryItem: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let points: String
    let icon: String
    let isNegative: Bool
}

// MARK: - VIP ViewModel
@MainActor
class VIPViewModel: ObservableObject {
    @Published var vip: VIPInfo?
    @Published var user: User?
    @Published var isUpgrading = false
    @Published var errorMessage: String? = nil

    let privileges: [VIPPrivilege] = [
        VIPPrivilege(title: "专享价", desc: "会员专属折扣", icon: "tag.fill", color: .red),
        VIPPrivilege(title: "生日礼", desc: "生日礼包", icon: "gift.fill", color: .orange),
        VIPPrivilege(title: "专属客服", desc: "优先客服", icon: "headphones", color: .blue),
        VIPPrivilege(title: "免运费", desc: "每月免运费券", icon: "shippingbox.fill", color: .green),
        VIPPrivilege(title: "积分加倍", desc: "购物积分翻倍", icon: "star.fill", color: .yellow),
        VIPPrivilege(title: "会员日", desc: "每月会员日", icon: "calendar", color: .purple)
    ]

    let benefits: [VIPBenefit] = [
        VIPBenefit(id: UUID(), title: "专享折扣", desc: "全场商品享受会员专属价", icon: "percent", color: .red, isNew: false),
        VIPBenefit(id: UUID(), title: "每月优惠券包", desc: "每月领取平台优惠券（价值100元+）", icon: "ticket.fill", color: .orange, isNew: true),
        VIPBenefit(id: UUID(), title: "生日礼包", desc: "生日当月领取专属礼包", icon: "gift.fill", color: .purple, isNew: false),
        VIPBenefit(id: UUID(), title: "专属客服", desc: "7x24小时优先客服接入", icon: "headphones", color: .blue, isNew: false),
        VIPBenefit(id: UUID(), title: "免运费券", desc: "每月赠送3张免运费券", icon: "shippingbox.fill", color: .green, isNew: true),
        VIPBenefit(id: UUID(), title: "积分翻倍", desc: "购物享受积分双倍累计", icon: "star.fill", color: .yellow, isNew: false)
    ]

    let benefitGridItems: [VIPGridBenefit] = [
        VIPGridBenefit(title: "专享券", icon: "tag"),
        VIPGridBenefit(title: "免费配送", icon: "shippingbox"),
        VIPGridBenefit(title: "专属客服", icon: "message"),
        VIPGridBenefit(title: "生日礼包", icon: "gift")
    ]

    let privilegeRows: [VIPActionRow] = [
        VIPActionRow(title: "专享优惠券", desc: "每月4张专属优惠券", icon: "tag", action: "领取"),
        VIPActionRow(title: "专享价商品", desc: "会员专属低价", icon: "message", action: "查看")
    ]

    let historyItems: [VIPHistoryItem] = [
        VIPHistoryItem(title: "购物赠送", time: "2026-03-27 14:30", points: "+200", icon: "shippingbox", isNegative: false),
        VIPHistoryItem(title: "积分兑换优惠券", time: "2026-03-26 10:15", points: "-100", icon: "gift", isNegative: true)
    ]

    func load() async {
        async let vipTask = VIPInfo.getVIP()
        async let userTask = User.getProfile()
        do {
            vip = try await vipTask
        } catch {
            errorMessage = userFacingErrorMessage(error, fallback: "会员信息加载失败")
        }
        do {
            user = try await userTask
        } catch {
            errorMessage = userFacingErrorMessage(error, fallback: "个人资料加载失败")
        }
    }

    func upgrade() async {
        isUpgrading = true
        do {
            vip = try await VIPInfo.upgrade()
            errorMessage = "会员升级成功"
        } catch {
            errorMessage = userFacingErrorMessage(error, fallback: "会员升级失败")
        }
        isUpgrading = false
    }
}

#Preview {
    NavigationStack {
        VIPView()
    }
}
