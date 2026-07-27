import SwiftUI

struct CouponView: View {
    @EnvironmentObject private var appNavigation: AppNavigation
    @StateObject private var viewModel = CouponViewModel()


    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            tabBar

            // Coupon List
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredCoupons.isEmpty {
                emptyView
            } else {
                couponList
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle("优惠券")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .toast($viewModel.errorMessage, bottomPadding: 80)
        .task {
            await viewModel.loadCoupons()
        }
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

            Button(action: { appNavigation.selectedTab = .category }) {
                Text("去逛逛")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 42)
                    .background(DesignSystem.Colors.accent)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Coupon Card
struct CouponCard: View {
    @EnvironmentObject private var appNavigation: AppNavigation
    @Environment(\.dismiss) private var dismiss
    let coupon: Coupon

    private let gradientColors = [Color(hex: "0F766E"), Color(hex: "45A69B")]

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
                    Button(action: {
                        appNavigation.selectedTab = .cart
                        dismiss()
                    }) {
                        Text("立即使用")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                            .background(DesignSystem.Colors.accent)
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
    let id: String
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
    @Published var coupons: [Coupon] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

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

    @MainActor
    func loadCoupons() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let remoteCoupons = try await UserCoupon.getCoupons()
            errorMessage = nil
            coupons = remoteCoupons.map { coupon in
                Coupon(
                    id: coupon.id,
                    title: coupon.name,
                    desc: coupon.description,
                    value: coupon.discountValue,
                    condition: coupon.threshold,
                    dateRange: coupon.time,
                    status: CouponStatus(rawValue: coupon.status)
                )
            }
        } catch {
            coupons = []
            errorMessage = userFacingErrorMessage(error, fallback: "优惠券加载失败")
        }
    }
}

private extension CouponStatus {
    init(rawValue: String) {
        switch rawValue {
        case "used":
            self = .used
        case "expired":
            self = .expired
        default:
            self = .available
        }
    }
}

#Preview {
    NavigationStack {
        CouponView()
    }
    .environmentObject(AppNavigation())
}
