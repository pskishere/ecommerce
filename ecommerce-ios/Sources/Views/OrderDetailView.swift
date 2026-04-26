import SwiftUI

struct OrderDetailView: View {
    let order: Order

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    // Status Section
                    statusSection

                    // Address Section
                    addressSection

                    // Products Section
                    productsSection

                    // Order Info Section
                    orderInfoSection

                    // Logistics Section (for shipped orders)
                    if order.status == .shipped {
                        logisticsSection
                    }

                    Spacer()
                        .frame(height: 80)
                }
                .padding(.top, 10)
            }
            .background(Color(hex: "F5F5F5"))

            // Bottom Bar
            bottomBar
        }
        .navigationTitle("订单详情")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
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
        case .pending: return accentColor
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
                        .foregroundStyle(accentColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("林小琳")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "1A1A1A"))
                    Text("138****8888")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "666666"))
                }
                Text("广东省广州市天河区珠江新城花城大道88号华夏中心A栋1501室")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "999999"))
                    .lineSpacing(2)
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
                    .foregroundStyle(accentColor)
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
                infoRow(label: "商品总价", value: "¥\(order.totalAmount)")
                infoRow(label: "运费", value: "免运费")
                infoRow(label: "优惠", value: "-¥0")
                infoRow(label: "订单编号", value: order.orderNumber, showCopy: true)
                infoRow(label: "下单时间", value: "2026-03-15 14:32:18")
                infoRow(label: "支付方式", value: "微信支付")
                infoRow(label: "实付金额", value: "¥\(order.totalAmount)", isHighlighted: true, hasBorder: false)
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
                        .foregroundStyle(isHighlighted ? accentColor : Color(hex: "1A1A1A"))

                    if showCopy {
                        Button(action: {}) {
                            Text("复制")
                                .font(.system(size: 12))
                                .foregroundStyle(accentColor)
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
        [
            ("您的订单已由顺丰快递取件，正在配送中", "2026-03-27 14:20:00", true),
            ("顺丰快递已揽收，正在发往广州转运中心", "2026-03-27 08:30:00", true),
            ("商家正在准备商品，请耐心等待", "2026-03-26 20:15:00", true),
            ("订单已支付，等待商家发货", "2026-03-27 10:35:12", false)
        ]
    }

    private func logisticsItem(item: (text: String, time: String, isActive: Bool), isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Dot column - 11pt width, dot with 4pt top offset
            VStack(spacing: 0) {
                Circle()
                    .fill(item.isActive ? accentColor : Color(hex: "DDDDDD"))
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
                Button(action: {}) {
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

                Button(action: {}) {
                    Text("去支付")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
            } else if order.status == .shipped {
                Button(action: {}) {
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

                Button(action: {}) {
                    Text("确认收货")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
            } else if order.status == .completed {
                Button(action: {}) {
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

                Button(action: {}) {
                    Text("去评价")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.white)
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
                OrderProduct(id: "preview-product-1", name: "时尚简约腕表", spec: "黑色经典款", price: 299, quantity: 1, image: "https://picsum.photos/200/200?random=1"),
                OrderProduct(id: "preview-product-2", name: "无线蓝牙耳机", spec: "白色标配版", price: 199, quantity: 2, image: "https://picsum.photos/200/200?random=2")
            ]
        ))
    }
}