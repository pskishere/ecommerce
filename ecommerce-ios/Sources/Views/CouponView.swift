import SwiftUI

struct CouponView: View {
    @StateObject private var viewModel = CouponViewModel()

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            tabBar

            // Coupon List
            if viewModel.filteredCoupons.isEmpty {
                emptyView
            } else {
                couponList
            }
        }
        .background(Color(hex: "F5F5F5"))
        .navigationTitle("优惠券")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        ContentTab(
            tabs: viewModel.tabs.map { ContentTabItem(value: $0, label: $0) },
            selectedTab: $viewModel.selectedTab
        )
    }

    // MARK: - Coupon List
    private var couponList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.filteredCoupons) { coupon in
                    CouponCard(coupon: coupon)
                }
            }
            .padding(12)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "ticket")
                .font(.system(size: 48))
                .foregroundStyle(Color(.tertiaryLabel))

            Text("暂无优惠券")
                .font(.system(size: 14))
                .foregroundStyle(Color(.secondaryLabel))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Coupon Card
struct CouponCard: View {
    let coupon: Coupon

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)
    private let gradientColors = [Color(hex: "FF6B4A"), Color(hex: "FF8E6B")]

    var body: some View {
        HStack(spacing: 0) {
            // Left - Orange section with gradient
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110)

                VStack(spacing: 4) {
                    HStack(alignment: .top, spacing: 2) {
                        Text("¥")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(coupon.value)")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                    }

                    Text(coupon.condition)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(width: 110, height: 112)

            // Right - White info section
            VStack(alignment: .trailing, spacing: 3) {
                Text(coupon.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .lineLimit(1)

                Text(coupon.desc)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "999999"))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(coupon.dateRange)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "BBBBBB"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)

                if coupon.status == .available {
                    Button(action: {}) {
                        Text("立即领取")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                            .background(accentColor)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 6)
                } else if coupon.status == .used {
                    statusTag(text: "已使用")
                } else {
                    statusTag(text: "已失效")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(Color.white)
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 0,
                        bottomLeading: 0,
                        bottomTrailing: 12,
                        topTrailing: 12
                    )
                )
            )
        }
        .frame(height: 112)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private func statusTag(text: String) -> some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundStyle(Color(hex: "999999"))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(hex: "F0F0F0"))
            .clipShape(Capsule())
            .padding(.top, 4)
    }
}

// MARK: - Coupon
struct Coupon: Identifiable {
    let id: UUID
    let title: String
    let desc: String
    let value: Int
    let condition: String
    let dateRange: String
    let status: CouponStatus
}

enum CouponStatus {
    case available
    case used
    case expired
}

// MARK: - Coupon ViewModel
class CouponViewModel: ObservableObject {
    @Published var selectedTab: String = "可用"
    @Published var coupons: [Coupon] = [
        Coupon(id: UUID(), title: "新人专享券", desc: "全场通用（除特例商品）", value: 20, condition: "满99元可用", dateRange: "2026.03.01-2026.03.31", status: .available),
        Coupon(id: UUID(), title: "限时折扣券", desc: "指定商品可用", value: 50, condition: "满299元可用", dateRange: "2026.03.01-2026.03.31", status: .available),
        Coupon(id: UUID(), title: "会员专享券", desc: "全场通用", value: 100, condition: "满599元可用", dateRange: "2026.03.01-2026.03.15", status: .available),
        Coupon(id: UUID(), title: "节日特惠券", desc: "全场通用", value: 30, condition: "满149元可用", dateRange: "2026.02.01-2026.02.28", status: .expired),
        Coupon(id: UUID(), title: "积分兑换券", desc: "指定商品可用", value: 15, condition: "满79元可用", dateRange: "2026.01.15-2026.02.15", status: .used)
    ]

    let tabs = ["可用", "已使用", "已过期"]

    var filteredCoupons: [Coupon] {
        switch selectedTab {
        case "可用":
            return coupons.filter { $0.status == .available }
        case "已使用":
            return coupons.filter { $0.status == .used }
        case "已过期":
            return coupons.filter { $0.status == .expired }
        default:
            return coupons
        }
    }
}

#Preview {
    NavigationStack {
        CouponView()
    }
}
