import SwiftUI

// MARK: - Order ViewModel
@MainActor
final class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var selectedTab: OrderStatus = .all

    var selectedTabBinding: Binding<String> {
        Binding(
            get: { self.selectedTab.rawValue },
            set: { newValue in
                if let tab = OrderStatus.allCases.first(where: { $0.rawValue == newValue }) {
                    self.selectedTab = tab
                }
            }
        )
    }

    init() {
        Task {
            await loadOrders()
        }
    }

    var filteredOrders: [Order] {
        if selectedTab == .all {
            return orders
        }
        return orders.filter { $0.status == selectedTab }
    }

    func loadOrders() async {
        orders = await Order.getList()
    }

    func selectTab(_ tab: OrderStatus) {
        selectedTab = tab
    }
}

// MARK: - Order View
struct OrderView: View {
    @StateObject private var viewModel = OrderViewModel()
    var initialStatus: OrderStatus = .all

    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            tabBar

            // Order List
            if viewModel.filteredOrders.isEmpty {
                emptyView
            } else {
                orderList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("我的订单")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .onAppear {
            viewModel.selectTab(initialStatus)
        }
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        ContentTab(
            tabs: OrderStatus.allCases.map { ContentTabItem(value: $0.rawValue, label: $0.displayText) },
            selectedTab: viewModel.selectedTabBinding
        )
    }

    // MARK: - Order List
    private var orderList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredOrders) { order in
                    NavigationLink(destination: OrderDetailView(order: order)) {
                        OrderCard(order: order)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("暂无相关订单")
                .font(.system(size: 14))
                .foregroundStyle(Color(.secondaryLabel))

            Button(action: {}) {
                Text("去逛逛")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(DesignSystem.Colors.accent)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Order Card
struct OrderCard: View {
    let order: Order

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Products
            products

            // Footer
            footer
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "store")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.accent)

                Text(order.store)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.label))
            }

            Spacer()

            Text(order.status.displayText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: order.status.color))
        }
        .padding(12)
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var products: some View {
        VStack(spacing: 10) {
            ForEach(order.products) { product in
                productRow(product)
            }
        }
        .padding(12)
    }

    private func productRow(_ product: OrderProduct) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Product Image - tappable to product detail
            NavigationLink(destination: ProductDetailView(product: Product(
                id: product.id,
                name: product.name,
                description: product.spec,
                price: product.price,
                originalPrice: nil,
                imageName: product.imageName,
                category: Category.all[0],
                rating: 4.8,
                reviewCount: 100,
                salesCount: 1000,
                isInStock: true
            ))) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(product.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .lineLimit(2)

                Text(product.spec)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.secondaryLabel))

                HStack {
                    Text(product.formattedPrice)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(.label))

                    Spacer()

                    Text("x\(product.quantity)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text("共\(order.totalQuantity)件商品，合计")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabel))

                Text("¥\(order.totalAmount)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(.label))

                Spacer()
            }

            actionButtons
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.5))
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch order.status {
        case .pending:
            HStack(spacing: 8) {
                Button(action: {}) {
                    Text("取消")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }

                Button(action: {}) {
                    Text("去付款")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
            }

        case .shipped:
            HStack(spacing: 8) {
                Button(action: {}) {
                    Text("查看物流")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }

                Button(action: {}) {
                    Text("确认收货")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
            }

        case .completed:
            HStack(spacing: 8) {
                Button(action: {}) {
                    Text("查看详情")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }

                Button(action: {}) {
                    Text("去评价")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
            }

        default:
            EmptyView()
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OrderView()
        .environmentObject(Cart())
}
