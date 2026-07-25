import Foundation
import SwiftUI

// MARK: - OrderStatus Enum
enum OrderStatus: String, CaseIterable, Codable, Hashable {
    case all = "all"
    case pending = "pending"
    case paid = "paid"
    case shipped = "shipped"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayText: String {
        switch self {
        case .all: return "全部"
        case .pending: return "待付款"
        case .paid: return "待发货"
        case .shipped: return "待收货"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        }
    }

    var color: String {
        switch self {
        case .pending: return "#FF6B4A"
        case .shipped: return "#007AFF"
        case .completed: return "#34C759"
        case .paid: return "#007AFF"
        case .cancelled: return "#999999"
        case .all: return "#666666"
        }
    }
}

// MARK: - OrderProduct Model
struct OrderProduct: Identifiable, Hashable, Codable {
    let id: String
    let productId: String
    let name: String
    let spec: String
    let price: Decimal
    let quantity: Int
    let image: String

    enum CodingKeys: String, CodingKey {
        case id, name, spec, price, quantity, image
        case productId = "product_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        productId = try container.decodeIfPresent(String.self, forKey: .productId) ?? id
        name = try container.decode(String.self, forKey: .name)
        spec = try container.decode(String.self, forKey: .spec)

        if let p = try? container.decode(Decimal.self, forKey: .price) {
            price = p
        } else if let p = try? container.decode(String.self, forKey: .price) {
            price = Decimal(string: p) ?? 0
        } else {
            price = 0
        }

        if let q = try? container.decode(Int.self, forKey: .quantity) {
            quantity = q
        } else if let q = try? container.decode(String.self, forKey: .quantity) {
            quantity = Int(q) ?? 0
        } else {
            quantity = 0
        }

        image = try container.decodeIfPresent(String.self, forKey: .image) ?? ""
    }

    // Manual initializer for previews/testing
    init(
        id: String,
        productId: String? = nil,
        name: String,
        spec: String,
        price: Decimal,
        quantity: Int,
        image: String
    ) {
        self.id = id
        self.productId = productId ?? id
        self.name = name
        self.spec = spec
        self.price = price
        self.quantity = quantity
        self.image = image
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productId, forKey: .productId)
        try container.encode(name, forKey: .name)
        try container.encode(spec, forKey: .spec)
        try container.encode("\(price)", forKey: .price)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(image, forKey: .image)
    }

    var formattedPrice: String {
        price.rmbText
    }

    var imageURL: URL? { URL(string: image) }
}

// MARK: - OrderAddress Model
struct OrderAddress: Codable, Hashable {
    let name: String
    let phone: String
    let province: String
    let city: String
    let district: String
    let detail: String

    var fullAddress: String {
        "\(province) \(city) \(district) \(detail)"
    }
}

// MARK: - Order Logistics Model
struct OrderLogisticsItem: Identifiable, Hashable, Codable {
    let text: String
    let time: String
    let active: Bool

    var id: String { "\(time)-\(text)" }
}

// MARK: - Order Model
struct Order: Identifiable, Hashable, Codable {
    let id: String
    let orderNumber: String  // backend returns 'id' as order number
    let store: String
    let status: OrderStatus
    let totalAmount: Decimal
    let payment: Decimal
    let freight: Decimal
    let discount: Decimal
    let address: OrderAddress?
    let payTime: String?
    let createdAt: String
    let shippedAt: String?
    let carrier: String
    let trackingNumber: String
    let logistics: [OrderLogisticsItem]
    let afterSaleStatus: String
    let afterSaleStatusText: String
    let afterSaleReason: String
    let afterSaleAppliedAt: String?
    let products: [OrderProduct]

    enum CodingKeys: String, CodingKey {
        case id, store, status
        case totalAmount = "total_amount"
        case payment, freight, discount, address
        case payTime = "pay_time"
        case createdAt = "created_at"
        case shippedAt = "shipped_at"
        case carrier
        case trackingNumber = "tracking_number"
        case logistics
        case afterSaleStatus = "after_sale_status"
        case afterSaleStatusText = "after_sale_status_text"
        case afterSaleReason = "after_sale_reason"
        case afterSaleAppliedAt = "after_sale_applied_at"
        case products
        case statusText = "statusText"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        orderNumber = id  // backend uses 'id' as order number
        store = try container.decode(String.self, forKey: .store)

        // Status can be string from backend
        let statusStr = try container.decode(String.self, forKey: .status)
        status = OrderStatus(rawValue: statusStr) ?? .pending

        // Handle decimal/string for amounts
        if let ta = try? container.decode(Decimal.self, forKey: .totalAmount) {
            totalAmount = ta
        } else if let ta = try? container.decode(String.self, forKey: .totalAmount) {
            totalAmount = Decimal(string: ta) ?? 0
        } else {
            totalAmount = 0
        }

        if let pm = try? container.decode(Decimal.self, forKey: .payment) {
            payment = pm
        } else if let pm = try? container.decode(String.self, forKey: .payment) {
            payment = Decimal(string: pm) ?? 0
        } else {
            payment = 0
        }

        if let fr = try? container.decode(Decimal.self, forKey: .freight) {
            freight = fr
        } else if let fr = try? container.decode(String.self, forKey: .freight) {
            freight = Decimal(string: fr) ?? 0
        } else {
            freight = 0
        }

        if let di = try? container.decode(Decimal.self, forKey: .discount) {
            discount = di
        } else if let di = try? container.decode(String.self, forKey: .discount) {
            discount = Decimal(string: di) ?? 0
        } else {
            discount = 0
        }

        address = try container.decodeIfPresent(OrderAddress.self, forKey: .address)
        payTime = try container.decodeIfPresent(String.self, forKey: .payTime)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        shippedAt = try container.decodeIfPresent(String.self, forKey: .shippedAt)
        carrier = try container.decodeIfPresent(String.self, forKey: .carrier) ?? ""
        trackingNumber = try container.decodeIfPresent(String.self, forKey: .trackingNumber) ?? ""
        logistics = try container.decodeIfPresent([OrderLogisticsItem].self, forKey: .logistics) ?? []
        afterSaleStatus = try container.decodeIfPresent(String.self, forKey: .afterSaleStatus) ?? "none"
        afterSaleStatusText = try container.decodeIfPresent(String.self, forKey: .afterSaleStatusText) ?? "未申请"
        afterSaleReason = try container.decodeIfPresent(String.self, forKey: .afterSaleReason) ?? ""
        afterSaleAppliedAt = try container.decodeIfPresent(String.self, forKey: .afterSaleAppliedAt)
        products = try container.decode([OrderProduct].self, forKey: .products)
    }

    var totalQuantity: Int {
        products.reduce(0) { $0 + $1.quantity }
    }

    var formattedTotal: String {
        totalAmount.rmbText
    }

    // Manual initializer for previews/testing
    init(
        id: String,
        orderNumber: String,
        store: String,
        status: OrderStatus,
        totalAmount: Decimal,
        payment: Decimal,
        freight: Decimal,
        discount: Decimal,
        address: OrderAddress?,
        payTime: String?,
        createdAt: String,
        shippedAt: String? = nil,
        carrier: String = "",
        trackingNumber: String = "",
        logistics: [OrderLogisticsItem] = [],
        afterSaleStatus: String = "none",
        afterSaleStatusText: String = "未申请",
        afterSaleReason: String = "",
        afterSaleAppliedAt: String? = nil,
        products: [OrderProduct]
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.store = store
        self.status = status
        self.totalAmount = totalAmount
        self.payment = payment
        self.freight = freight
        self.discount = discount
        self.address = address
        self.payTime = payTime
        self.createdAt = createdAt
        self.shippedAt = shippedAt
        self.carrier = carrier
        self.trackingNumber = trackingNumber
        self.logistics = logistics
        self.afterSaleStatus = afterSaleStatus
        self.afterSaleStatusText = afterSaleStatusText
        self.afterSaleReason = afterSaleReason
        self.afterSaleAppliedAt = afterSaleAppliedAt
        self.products = products
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(store, forKey: .store)
        try container.encode(status.rawValue, forKey: .status)
        try container.encode("\(totalAmount)", forKey: .totalAmount)
        try container.encode("\(payment)", forKey: .payment)
        try container.encode("\(freight)", forKey: .freight)
        try container.encode("\(discount)", forKey: .discount)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(payTime, forKey: .payTime)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(shippedAt, forKey: .shippedAt)
        try container.encode(carrier, forKey: .carrier)
        try container.encode(trackingNumber, forKey: .trackingNumber)
        try container.encode(logistics, forKey: .logistics)
        try container.encode(afterSaleStatus, forKey: .afterSaleStatus)
        try container.encode(afterSaleStatusText, forKey: .afterSaleStatusText)
        try container.encode(afterSaleReason, forKey: .afterSaleReason)
        try container.encodeIfPresent(afterSaleAppliedAt, forKey: .afterSaleAppliedAt)
        try container.encode(products, forKey: .products)
    }
}

// MARK: - Order API
extension Order {
    static func getList(status: OrderStatus = .all) async throws -> [Order] {
        var endpoint = APIEndpoints.orders
        if status != .all {
            endpoint += "?status=\(status.rawValue)"
        }
        return try await APIClient.shared.request(endpoint: endpoint, requiresAuth: true)
    }

    static func getOrder(by id: String) async throws -> Order {
        return try await APIClient.shared.request(endpoint: APIEndpoints.order(id), requiresAuth: true)
    }

    // MARK: - Order Actions
    static func cancelOrder(id: String) async throws {
        try await APIClient.shared.requestNoData(endpoint: APIEndpoints.orderCancel(id), method: "PUT", requiresAuth: true)
    }

    static func payOrder(id: String, method: String = "wxpay") async throws -> Order {
        struct PayRequest: Encodable { let paymentMethod: String }
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.orderPay(id),
            method: "PUT",
            body: PayRequest(paymentMethod: method),
            requiresAuth: true
        )
    }

    static func shipOrder(id: String, carrier: String = "顺丰速运", trackingNumber: String = "") async throws -> Order {
        struct ShipRequest: Encodable {
            let carrier: String
            let trackingNumber: String
        }
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.orderShip(id),
            method: "PUT",
            body: ShipRequest(carrier: carrier, trackingNumber: trackingNumber),
            requiresAuth: true
        )
    }

    static func confirmReceipt(id: String) async throws -> Order {
        return try await APIClient.shared.request(endpoint: APIEndpoints.orderConfirm(id), method: "PUT", requiresAuth: true)
    }

    static func requestAfterSale(id: String, reason: String) async throws -> Order {
        struct RequestBody: Encodable { let reason: String }
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.orderAfterSale(id),
            method: "POST",
            body: RequestBody(reason: reason),
            requiresAuth: true
        )
    }

    static func buyAgain(id: String) async throws -> Int {
        struct BuyAgainResponse: Decodable {
            let addedCount: Int

            enum CodingKeys: String, CodingKey {
                case addedCount = "added_count"
            }
        }
        let response: BuyAgainResponse = try await APIClient.shared.request(
            endpoint: APIEndpoints.orderBuyAgain(id),
            method: "POST",
            requiresAuth: true
        )
        return response.addedCount
    }

    static func createOrder(cartItemIds: [String], addressId: String, couponId: String? = nil, remark: String = "") async throws -> Order {
        struct CreateRequest: Encodable {
            let cartItemIds: [String]
            let addressId: String
            let couponId: String?
            let remark: String
        }
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.orders,
            method: "POST",
            body: CreateRequest(cartItemIds: cartItemIds, addressId: addressId, couponId: couponId, remark: remark),
            requiresAuth: true
        )
    }
}

// MARK: - CheckoutCoupon Model
struct CheckoutCoupon: Identifiable, Codable {
    let id: String
    let name: String
    let value: Decimal
    let threshold: String
    let thresholdAmount: Int
    let description: String
    let time: String
    var usable: Bool = true

    var discountValue: Int { Int(truncating: value as NSDecimalNumber) }
}

// MARK: - PaymentMethod Model
struct PaymentMethod: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color

    static let supportedMethods: [PaymentMethod] = [
        PaymentMethod(id: "wxpay", name: "微信支付", icon: "checkmark.circle.fill", color: .green),
        PaymentMethod(id: "alipay", name: "支付宝", icon: "creditcard.fill", color: .blue),
    ]
}
