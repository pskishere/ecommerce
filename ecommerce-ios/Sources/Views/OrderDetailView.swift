import SwiftUI

struct OrderDetailView: View {
    @State private var order: Order
    @Environment(\.dismiss) private var dismiss
    @State private var toast: String? = nil
    @State private var showPayment = false
    @State private var showAfterSalePrompt = false
    @State private var afterSaleReason = "商品不合适，需要售后处理"

    init(order: Order) {
        self._order = State(initialValue: order)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    statusSection
                    addressSection
                    productsSection
                    orderInfoSection
                    if order.afterSaleStatus != "none" {
                        afterSaleSection
                    }
                    if !order.logistics.isEmpty {
                        logisticsSection
                    }
                    Spacer().frame(height: 80)
                }
                .padding(.top, 10)
            }
            .background(Color(hex: "F5F5F5"))

            bottomBar
        }
        .toast($toast, bottomPadding: 80)
        .navigationTitle("订单详情")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .navigationDestination(isPresented: $showPayment) {
            PaymentView(
                order: order,
                onComplete: {
                    showPayment = false
                },
                onPaid: { updatedOrder in
                    order = updatedOrder
                }
            )
        }
        .alert("申请售后", isPresented: $showAfterSalePrompt) {
            TextField("请输入售后原因", text: $afterSaleReason)
            Button("取消", role: .cancel) { }
            Button("提交") {
                submitAfterSale()
            }
        } message: {
            Text("提交后客服会尽快处理。")
        }
    }

    // MARK: - Status Section
    private var statusSection: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusIconBackground)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: statusIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(statusIconColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(order.status.displayText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "1A1A1A"))

                Text(statusSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "666666"))
            }

            Spacer()
        }
        .padding(20)
        .background(Color.white)
    }

    private var statusIconBackground: Color {
        switch order.status {
        case .pending: return Color(hex: "FFF0ED")
        case .paid: return Color(hex: "E8F0FE")
        case .shipped: return Color(hex: "E8F5E9")
        case .completed: return Color(hex: "E8F5E9")
        default: return Color(hex: "F5F5F5")
        }
    }

    private var statusIconColor: Color {
        switch order.status {
        case .pending: return DesignSystem.Colors.accent
        case .paid: return Color.blue
        case .shipped: return Color.green
        case .completed: return Color.green
        default: return Color.gray
        }
    }

    private var statusIcon: String {
        switch order.status {
        case .pending: return "clock.fill"
        case .paid: return "shippingbox.fill"
        case .shipped: return "shippingbox.fill"
        case .completed: return "checkmark.circle.fill"
        default: return "doc.text.fill"
        }
    }

    private var statusSubtitle: String {
        switch order.status {
        case .pending: return "请在30分钟内完成支付"
        case .paid: return "商家正在准备商品"
        case .shipped: return "您的订单正在配送中"
        case .completed: return "感谢您的购买"
        default: return ""
        }
    }

    // MARK: - Address Section
    private var addressSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color(red: 1.0, green: 0.94, blue: 0.92))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(DesignSystem.Colors.accent)
                )

            if let addr = order.address {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(addr.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "1A1A1A"))
                        Text(addr.phone)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "666666"))
                    }
                    Text(addr.fullAddress)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "999999"))
                        .lineSpacing(2)
                }
            } else {
                Text("暂无收货地址")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "999999"))
            }

            Spacer()
        }
        .padding(20)
        .background(Color.white)
    }

    // MARK: - Products Section
    private var productsSection: some View {
        VStack(spacing: 0) {
            // Store Header
            HStack(spacing: 8) {
                Image(systemName: "store")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignSystem.Colors.accent)
                Text(order.store)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "CCCCCC"))
            }
            .padding(12)
            .background(Color(hex: "F8F8F8"))

            // Products
            ForEach(order.products) { product in
                productRow(product)
                if product.id != order.products.last?.id {
                    Divider()
                        .padding(.leading, 82)
                }
            }
        }
    }

    private func productRow(_ product: OrderProduct) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Product Image
            NavigationLink(destination: ProductDetailView(product: Product(
                id: product.productId,
                name: product.name,
                description: product.spec,
                price: product.price,
                originalPrice: nil,
                image: product.image,
                subcategoryRef: nil,
                rating: 5,
                reviewCount: 0,
                salesCount: 0,
                isInStock: true,
                tag: ""
            ))) {
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "F8F8F8"))
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .lineLimit(2)

                Text(product.spec)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "999999"))
                    .padding(.top, 2)

                HStack {
                    Text(product.formattedPrice)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "1A1A1A"))

                    Spacer()

                    Text("x\(product.quantity)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "999999"))
                }
            }
        }
        .padding(12)
    }

    // MARK: - Order Info Section
    private var orderInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("订单信息")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "1A1A1A"))
                .padding(12)

            VStack(spacing: 0) {
                infoRow(label: "商品总价", value: order.totalAmount.rmbText)
                infoRow(label: "运费", value: order.freight == 0 ? "免运费" : order.freight.rmbText)
                infoRow(label: "优惠", value: order.discount > 0 ? "-¥\(order.discount)" : "-")
                infoRow(label: "订单编号", value: order.orderNumber, showCopy: true)
                infoRow(label: "下单时间", value: order.createdAt)
                infoRow(label: "支付方式", value: "微信支付")
                infoRow(label: "实付金额", value: order.payment.rmbText, isHighlighted: true, hasBorder: false)
            }
        }
        .background(Color.white)
    }

    private func infoRow(label: String, value: String, showCopy: Bool = false, isHighlighted: Bool = false, hasBorder: Bool = true) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "999999"))

                Spacer()

                HStack(spacing: 8) {
                    Text(value)
                        .font(.system(size: isHighlighted ? 16 : 13, weight: isHighlighted ? .bold : .regular))
                        .foregroundStyle(isHighlighted ? DesignSystem.Colors.accent : Color(hex: "1A1A1A"))

                    if showCopy {
                        Button(action: {
                            UIPasteboard.general.string = value
                            toast = "已复制"
                        }) {
                            Text("复制")
                                .font(.system(size: 12))
                                .foregroundStyle(DesignSystem.Colors.accent)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if hasBorder {
                Rectangle()
                    .fill(Color(hex: "F5F5F5"))
                    .frame(height: 0.5)
                    .padding(.leading, 12)
            }
        }
    }

    // MARK: - After Sale Section
    private var afterSaleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("售后信息")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "1A1A1A"))
                .padding(12)

            VStack(spacing: 0) {
                infoRow(label: "售后状态", value: order.afterSaleStatusText)
                infoRow(label: "申请原因", value: order.afterSaleReason.isEmpty ? "-" : order.afterSaleReason, hasBorder: false)
            }
        }
        .background(Color.white)
    }

    // MARK: - Logistics Section
    private var logisticsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("物流信息")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "1A1A1A"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(Array(logisticsItems.enumerated()), id: \.offset) { index, item in
                    logisticsItem(item: item, isLast: index == logisticsItems.count - 1)
                }
            }
        }
        .padding(12)
        .background(Color.white)
    }

    private var logisticsItems: [(text: String, time: String, isActive: Bool)] {
        order.logistics.map { ($0.text, $0.time, $0.active) }
    }

    private func logisticsItem(item: (text: String, time: String, isActive: Bool), isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Dot column - 11pt width, dot with 4pt top offset
            VStack(spacing: 0) {
                Circle()
                    .fill(item.isActive ? DesignSystem.Colors.accent : Color(hex: "DDDDDD"))
                    .frame(width: 11, height: 11)
                    .padding(.top, 4)

                if !isLast {
                    Rectangle()
                        .fill(Color(hex: "E5E5E5"))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 11)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .lineSpacing(2)

                Text(item.time)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "999999"))
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isLast ? 0 : 16)
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 10) {
            if order.status == .pending {
                Button(action: {
                    Task {
                        do {
                            _ = try await Order.cancelOrder(id: order.id)
                            toast = "已取消订单"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                        } catch {
                            toast = userFacingErrorMessage(error, fallback: "取消订单失败")
                        }
                    }
                }) {
                    Text("取消订单")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "FF3B30"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "FF3B30"), lineWidth: 1)
                        )
                }

                Button(action: { showPayment = true }) {
                    Text("去支付")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
            } else if order.status == .shipped {
                Button(action: {
                    toast = order.trackingNumber.isEmpty ? "物流信息已展示" : "运单号：\(order.trackingNumber)"
                }) {
                    Text("查看物流")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "666666"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "DDDDDD"), lineWidth: 1)
                        )
                }

                if order.afterSaleStatus == "none" {
                    Button(action: { showAfterSalePrompt = true }) {
                        Text("申请售后")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "666666"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color(hex: "DDDDDD"), lineWidth: 1)
                            )
                    }
                }

                Button(action: {
                    Task {
                        do {
                            let updated = try await Order.confirmReceipt(id: order.id)
                            order = updated
                            toast = "已确认收货"
                        } catch {
                            toast = userFacingErrorMessage(error, fallback: "确认收货失败")
                        }
                    }
                }) {
                    Text("确认收货")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
            } else if order.status == .completed {
                Button(action: buyAgain) {
                    Text("再次购买")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "666666"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "DDDDDD"), lineWidth: 1)
                        )
                }

                if order.afterSaleStatus == "none" {
                    Button(action: { showAfterSalePrompt = true }) {
                        Text("申请售后")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "666666"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color(hex: "DDDDDD"), lineWidth: 1)
                            )
                    }
                }

                NavigationLink(destination: ReviewView(product: reviewProduct)) {
                    Text("去评价")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.white)
    }

    private func submitAfterSale() {
        let reason = afterSaleReason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty else {
            toast = "请填写售后原因"
            return
        }
        Task {
            do {
                let updated = try await Order.requestAfterSale(id: order.id, reason: reason)
                order = updated
                toast = "售后申请已提交"
            } catch {
                toast = userFacingErrorMessage(error, fallback: "售后申请失败")
            }
        }
    }

    private func buyAgain() {
        Task {
            do {
                let count = try await Order.buyAgain(id: order.id)
                toast = count > 0 ? "已加入购物车" : "没有可加入购物车的商品"
            } catch {
                toast = userFacingErrorMessage(error, fallback: "再次购买失败")
            }
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
}

#Preview {
    NavigationStack {
        OrderDetailView(order: Order(
            id: "preview-order-1",
            orderNumber: "ORDER202603150001",
            store: "潮流优品官方旗舰店",
            status: .shipped,
            totalAmount: 697,
            payment: 697,
            freight: 0,
            discount: 0,
            address: nil,
            payTime: "2026-03-15 10:30:00",
            createdAt: "2026-03-15 10:30:00",
            products: [
                OrderProduct(id: "preview-product-1", name: "时尚简约腕表", spec: "黑色经典款", price: 299, quantity: 1, image: "http://localhost:8080/media/uploads/product-01-watch.webp"),
                OrderProduct(id: "preview-product-2", name: "无线蓝牙耳机", spec: "白色标配版", price: 199, quantity: 2, image: "http://localhost:8080/media/uploads/product-02-earbuds.webp")
            ]
        ))
    }
}
