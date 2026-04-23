import Foundation
import SwiftUI

// MARK: - OrderStatus Enum
enum OrderStatus: String, CaseIterable {
    case all = "all"
    case pending = "pending"
    case paid = "paid"
    case shipped = "shipped"
    case completed = "completed"

    var displayText: String {
        switch self {
        case .all: return "全部"
        case .pending: return "待付款"
        case .paid: return "待发货"
        case .shipped: return "待收货"
        case .completed: return "已完成"
        }
    }

    var color: String {
        switch self {
        case .pending: return "#FF6B4A"
        case .shipped: return "#007AFF"
        case .completed: return "#34C759"
        case .paid: return "#007AFF"
        case .all: return "#666666"
        }
    }
}

// MARK: - OrderProduct Model
struct OrderProduct: Identifiable, Hashable {
    let id: UUID
    let name: String
    let spec: String
    let price: Decimal
    let quantity: Int
    let imageName: String

    var formattedPrice: String {
        "¥\(price)"
    }
}

// MARK: - Order Model
struct Order: Identifiable, Hashable {
    let id: UUID
    let orderNumber: String
    let store: String
    let status: OrderStatus
    let products: [OrderProduct]
    let totalAmount: Decimal

    var totalQuantity: Int {
        products.reduce(0) { $0 + $1.quantity }
    }

    var formattedTotal: String {
        "¥\(totalAmount)"
    }
}

// MARK: - Order API
extension Order {
    // MARK: - Mock Data
    static let mockOrders: [Order] = [
        Order(id: UUID(), orderNumber: "ORDER20260327001", store: "潮流服饰旗舰店", status: .pending, products: [
            OrderProduct(id: UUID(), name: "简约纯棉T恤 夏季新款", spec: "白色 / M码", price: 89, quantity: 2, imageName: "product_01_watch"),
        ], totalAmount: 178),
        Order(id: UUID(), orderNumber: "ORDER20260326002", store: "数码精品汇", status: .shipped, products: [
            OrderProduct(id: UUID(), name: "无线蓝牙耳机 降噪款", spec: "黑色", price: 199, quantity: 1, imageName: "product_02_earbuds"),
            OrderProduct(id: UUID(), name: "极简陶瓷咖啡杯", spec: "大理石纹", price: 68, quantity: 1, imageName: "product_03_mug"),
        ], totalAmount: 267),
        Order(id: UUID(), orderNumber: "ORDER20260325003", store: "美妆护肤专营店", status: .completed, products: [
            OrderProduct(id: UUID(), name: "有机护肤精华液 30ml", spec: "30ml", price: 159, quantity: 1, imageName: "product_04_serum"),
        ], totalAmount: 159),
        Order(id: UUID(), orderNumber: "ORDER20260324004", store: "运动户外专营", status: .completed, products: [
            OrderProduct(id: UUID(), name: "经典帆布硫化鞋 低帮款", spec: "白色 / 42码", price: 229, quantity: 1, imageName: "product_05_sneakers"),
        ], totalAmount: 229),
        Order(id: UUID(), orderNumber: "ORDER20260323005", store: "皮具配饰店", status: .completed, products: [
            OrderProduct(id: UUID(), name: "头层牛皮钱包 短款", spec: "黑色", price: 99, quantity: 1, imageName: "product_06_wallet"),
        ], totalAmount: 99),
    ]

    // MARK: - API Methods (async with mock delay)
    private static func mockRequest<T>(_ data: T, delay: UInt64 = 300_000_000) async -> T {
        try? await Task.sleep(nanoseconds: delay)
        return data
    }

    static func getList() async -> [Order] {
        await mockRequest(mockOrders)
    }

    static func getList(for status: OrderStatus) async -> [Order] {
        if status == .all {
            return await getList()
        }
        return await mockRequest(mockOrders.filter { $0.status == status })
    }

    static func getOrder(by id: UUID) async -> Order? {
        await mockRequest(mockOrders.first { $0.id == id })
    }

    static func createOrder(items: [CartItem], addressId: UUID, couponId: UUID? = nil) async -> Order? {
        // Mock order creation
        return await mockRequest(Order(
            id: UUID(),
            orderNumber: "ORDER\(Int(Date().timeIntervalSince1970))",
            store: "潮流优品官方旗舰店",
            status: .pending,
            products: items.map { item in
                OrderProduct(
                    id: UUID(),
                    name: item.product.name,
                    spec: item.product.category.name,
                    price: item.product.price,
                    quantity: item.quantity,
                    imageName: item.product.imageName
                )
            },
            totalAmount: items.reduce(Decimal.zero) { $0 + $1.totalPrice }
        ))
    }

    static func cancelOrder(id: UUID) async -> Bool {
        await mockRequest(true)
    }

    static func payOrder(id: UUID) async -> Bool {
        await mockRequest(true)
    }

    static func confirmReceipt(id: UUID) async -> Bool {
        await mockRequest(true)
    }
}

// MARK: - Address Model (for checkout)
struct CheckoutAddress: Identifiable {
    let id: UUID
    let name: String
    let phone: String
    let province: String
    let city: String
    let district: String
    let detail: String
    let isDefault: Bool

    var fullAddress: String {
        "\(province) \(city) \(district) \(detail)"
    }

    static let mockAddresses: [CheckoutAddress] = [
        CheckoutAddress(id: UUID(), name: "林小琳", phone: "138****8888", province: "广东省", city: "广州市", district: "天河区", detail: "珠江新城花城大道88号华夏中心A栋1501室", isDefault: true),
        CheckoutAddress(id: UUID(), name: "林小琳", phone: "139****6666", province: "广东省", city: "深圳市", district: "南山区", detail: "科技园南区高新南七道R2-B栋5楼", isDefault: false),
        CheckoutAddress(id: UUID(), name: "王明", phone: "158****2222", province: "北京市", city: "北京市", district: "朝阳区", detail: "建国路89号华贸中心写字楼A座12层", isDefault: false),
    ]
}

// MARK: - CheckoutCoupon Model
struct CheckoutCoupon: Identifiable {
    let id: UUID
    let name: String
    let discount: Int
    let threshold: Int
    let desc: String
    let validUntil: String
    let usable: Bool

    static let mockCoupons: [CheckoutCoupon] = [
        CheckoutCoupon(id: UUID(), name: "新人专享券", discount: 20, threshold: 100, desc: "满100减20", validUntil: "2026-04-30", usable: true),
        CheckoutCoupon(id: UUID(), name: "平台满减券", discount: 10, threshold: 50, desc: "满50减10", validUntil: "2026-04-15", usable: true),
        CheckoutCoupon(id: UUID(), name: "限时大额券", discount: 50, threshold: 300, desc: "满300减50", validUntil: "2026-04-30", usable: false),
    ]
}

// MARK: - PaymentMethod Model
struct PaymentMethod: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: Color

    static let mockMethods: [PaymentMethod] = [
        PaymentMethod(id: UUID(), name: "微信支付", icon: "checkmark.circle.fill", color: .green),
        PaymentMethod(id: UUID(), name: "支付宝", icon: "creditcard.fill", color: .blue),
    ]
}

// MARK: - CheckoutOrderItem Model
struct CheckoutOrderItem: Identifiable {
    let id: UUID
    let name: String
    let spec: String
    let price: Decimal
    let quantity: Int
    let imageName: String

    static let mockItems: [CheckoutOrderItem] = [
        CheckoutOrderItem(id: UUID(), name: "时尚简约腕表", spec: "黑色经典款 / 标准版", price: 299, quantity: 1, imageName: "product_01_watch"),
        CheckoutOrderItem(id: UUID(), name: "无线蓝牙耳机", spec: "白色 / 标配版", price: 199, quantity: 2, imageName: "product_02_earbuds"),
    ]
}
