import SwiftUI

// MARK: - Order ViewModel
@MainActor
final class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var selectedTab: OrderStatus = .all
    @Published var errorMessage: String? = nil
    @Published var isLoading = false

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
        isLoading = true
        defer { isLoading = false }
        do {
            orders = try await Order.getList()
            errorMessage = nil
        } catch {
            errorMessage = userFacingErrorMessage(error, fallback: "订单加载失败")
        }
    }

    func selectTab(_ tab: OrderStatus) {
        selectedTab = tab
    }
}

// MARK: - Order View
struct OrderView: View {
    @EnvironmentObject private var appNavigation: AppNavigation
    @StateObject private var viewModel = OrderViewModel()
    var initialStatus: OrderStatus = .all

    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            tabBar

            // Order List
            if viewModel.isLoading && viewModel.orders.isEmpty {
                AppInlineLoadingView(title: "订单加载中")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredOrders.isEmpty {
                emptyView
            } else {
                orderList
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle("我的订单")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .toast($viewModel.errorMessage, bottomPadding: 80)
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
                        OrderCard(order: order, onRefresh: {
                            Task { await viewModel.loadOrders() }
                        })
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

// MARK: - Order Card
struct OrderCard: View {
    let order: Order
    var onRefresh: (() -> Void)? = nil

    @State private var toast: String? = nil
    @State private var showPayment = false
    @State private var showCancelConfirm = false
    @State private var showReceiptConfirm = false
    @State private var isActing = false

    var body: some View {
        VStack(spacing: 0) {
            header
            products
            footer
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .toast($toast, bottomPadding: 16)
        .confirmationDialog("取消订单", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("确认取消", role: .destructive) {
                Task { await cancelOrder() }
            }
            Button("再想想", role: .cancel) { }
        } message: {
            Text("取消后订单将关闭。")
        }
        .confirmationDialog("确认收货", isPresented: $showReceiptConfirm, titleVisibility: .visible) {
            Button("确认收货") {
                Task { await confirmReceipt() }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("请确认已经收到商品。")
        }
        .navigationDestination(isPresented: $showPayment) {
            PaymentView(
                order: order,
                onComplete: {
                    showPayment = false
                    onRefresh?()
                },
                onPaid: { _ in
                    onRefresh?()
                }
            )
        }
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
            NavigationLink(destination: ProductDetailView(product: Product(
                id: product.productId,
                name: product.name,
                description: product.spec,
                price: product.price,
                originalPrice: nil,
                image: product.image,
                subcategoryRef: nil,
                rating: 4.8,
                reviewCount: 100,
                salesCount: 1000,
                isInStock: true,
                tag: ""
            ))) {
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.secondarySystemBackground))
                }
                .frame(width: 70, height: 70)
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

                Text(order.totalAmount.rmbText)
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
                Button(action: { showCancelConfirm = true }) {
                    Text(isActing ? "处理中" : "取消")
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
                .disabled(isActing)

                Button(action: {
                    showPayment = true
                }) {
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
                NavigationLink(destination: OrderDetailView(order: order)) {
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
                .buttonStyle(.plain)

                Button(action: { showReceiptConfirm = true }) {
                    Text(isActing ? "处理中" : "确认收货")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
                .disabled(isActing)
            }

        case .completed:
            HStack(spacing: 8) {
                Button(action: {
                    Task { await buyAgain() }
                }) {
                    Text(isActing ? "处理中" : "再次购买")
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
                .disabled(isActing)

                NavigationLink(destination: ReviewView(product: reviewProduct)) {
                    Text("去评价")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

        default:
            EmptyView()
        }
    }

    private var reviewProduct: Product {
        let item = order.products.first
        return Product(
            id: item?.productId ?? "",
            name: item?.name ?? "商品",
            description: item?.spec ?? "",
            price: item?.price ?? 0,
            originalPrice: nil,
            image: item?.image ?? "",
            subcategoryRef: nil,
            rating: 5,
            reviewCount: 0,
            salesCount: 0,
            isInStock: true,
            tag: ""
        )
    }

    private func cancelOrder() async {
        guard !isActing else { return }
        isActing = true
        defer { isActing = false }
        do {
            try await Order.cancelOrder(id: order.id)
            toast = "已取消订单"
            onRefresh?()
        } catch {
            toast = userFacingErrorMessage(error, fallback: "取消订单失败")
        }
    }

    private func confirmReceipt() async {
        guard !isActing else { return }
        isActing = true
        defer { isActing = false }
        do {
            _ = try await Order.confirmReceipt(id: order.id)
            toast = "已确认收货"
            onRefresh?()
        } catch {
            toast = userFacingErrorMessage(error, fallback: "确认收货失败")
        }
    }

    private func buyAgain() async {
        guard !isActing else { return }
        isActing = true
        defer { isActing = false }
        do {
            let count = try await Order.buyAgain(id: order.id)
            toast = count > 0 ? "已加入购物车" : "没有可加入购物车的商品"
        } catch {
            toast = userFacingErrorMessage(error, fallback: "再次购买失败")
        }
    }
}

#Preview {
    OrderView()
        .environmentObject(Cart())
        .environmentObject(AppNavigation())
}
