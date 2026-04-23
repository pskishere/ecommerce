import Foundation

// MARK: - User Model
struct User: Identifiable {
    let id: UUID
    let name: String
    let email: String
    let avatarName: String

    static let mock = User(
        id: UUID(),
        name: "林小琳",
        email: "linxiaolin@example.com",
        avatarName: "person.circle.fill"
    )
}

// MARK: - Address Model
struct Address: Identifiable {
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
}

// MARK: - Favorite Product (simplified for list display)
struct FavoriteProduct: Identifiable {
    let id: UUID
    let name: String
    let price: Decimal
    let originalPrice: Decimal?
    let imageName: String
    let sales: String
}

// MARK: - Browse History Item
struct HistoryItem: Identifiable {
    let id: UUID
    let name: String
    let price: Decimal
    let imageName: String
    let time: String
}

// MARK: - Notification Model (for user notifications)
struct UserNotification: Identifiable {
    let id: UUID
    let type: NotificationType
    let name: String
    let time: String
    let content: String
    let action: String

    enum NotificationType: String {
        case logistics
        case order
        case promo
        case sys
    }
}

// MARK: - UserCoupon Model (for user coupons)
struct UserCoupon: Identifiable {
    let id: UUID
    let name: String
    let value: Int
    let threshold: String
    let desc: String
    let time: String
}

// MARK: - User API
extension User {
    // MARK: - Mock Data
    static let mockAddresses: [Address] = [
        Address(id: UUID(), name: "林小琳", phone: "138****8888", province: "广东省", city: "广州市", district: "天河区", detail: "珠江新城花城大道88号华夏中心A栋1501室", isDefault: true),
        Address(id: UUID(), name: "林小琳", phone: "139****9999", province: "广东省", city: "深圳市", district: "南山区", detail: "科技园南区深南大道9996号松日鼎盛大厦8楼", isDefault: false),
    ]

    static let mockFavorites: [FavoriteProduct] = [
        FavoriteProduct(id: UUID(), name: "时尚简约腕表", price: 299, originalPrice: 899, imageName: "product_01_watch", sales: "2.3万+"),
        FavoriteProduct(id: UUID(), name: "无线蓝牙耳机", price: 199, originalPrice: 499, imageName: "product_02_earbuds", sales: "1.8万+"),
        FavoriteProduct(id: UUID(), name: "极简陶瓷咖啡杯", price: 39, originalPrice: 79, imageName: "product_03_mug", sales: "9800+"),
        FavoriteProduct(id: UUID(), name: "有机护肤精华液 30ml", price: 129, originalPrice: 399, imageName: "product_04_serum", sales: "8600+"),
        FavoriteProduct(id: UUID(), name: "经典帆布硫化鞋", price: 159, originalPrice: 359, imageName: "product_05_sneakers", sales: "1.2万+"),
        FavoriteProduct(id: UUID(), name: "头层牛皮钱包", price: 189, originalPrice: 399, imageName: "product_06_wallet", sales: "1.5万+"),
    ]

    static let mockHistory: [HistoryItem] = [
        HistoryItem(id: UUID(), name: "时尚简约腕表", price: 299, imageName: "product_01_watch", time: "今天 14:23"),
        HistoryItem(id: UUID(), name: "无线蓝牙耳机", price: 199, imageName: "product_02_earbuds", time: "今天 13:45"),
        HistoryItem(id: UUID(), name: "有机护肤精华液 30ml", price: 129, imageName: "product_04_serum", time: "昨天 21:10"),
        HistoryItem(id: UUID(), name: "经典帆布硫化鞋", price: 159, imageName: "product_05_sneakers", time: "昨天 18:32"),
        HistoryItem(id: UUID(), name: "极简陶瓷咖啡杯", price: 39, imageName: "product_03_mug", time: "3天前"),
    ]

    static let mockCoupons: (available: [UserCoupon], used: [UserCoupon], expired: [UserCoupon]) = (
        available: [
            UserCoupon(id: UUID(), name: "新人专享券", value: 20, threshold: "满99元可用", desc: "限新用户首次下单", time: "2026-03-27 至 2026-04-27"),
            UserCoupon(id: UUID(), name: "限时满减券", value: 50, threshold: "满299元可用", desc: "全品类通用", time: "2026-03-27 至 2026-04-10"),
            UserCoupon(id: UUID(), name: "会员专享券", value: 10, threshold: "无门槛", desc: "会员专享优惠", time: "2026-03-27 至 2026-04-27"),
            UserCoupon(id: UUID(), name: "品牌特惠券", value: 30, threshold: "满199元可用", desc: "限指定品牌商品", time: "2026-03-27 至 2026-03-31"),
        ],
        used: [
            UserCoupon(id: UUID(), name: "节日特惠券", value: 15, threshold: "满79元可用", desc: "春节活动券", time: "2026-02-01 至 2026-02-28"),
            UserCoupon(id: UUID(), name: "积分兑换券", value: 5, threshold: "无门槛", desc: "积分商城兑换", time: "2026-01-15 至 2026-01-15"),
        ],
        expired: [
            UserCoupon(id: UUID(), name: "周年庆券", value: 100, threshold: "满499元可用", desc: "周年庆活动", time: "2026-01-01 至 2026-01-31"),
        ]
    )

    static let mockNotifications: [UserNotification] = [
        UserNotification(id: UUID(), type: .logistics, name: "物流通知", time: "10:30", content: "您的订单已发货，快递顺丰SF1234567890，正在配送中，预计明天送达", action: "查看物流"),
        UserNotification(id: UUID(), type: .order, name: "订单提醒", time: "昨天", content: "您的订单已完成签收，感谢您购买潮流好物，期待下次光临~", action: "去评价"),
        UserNotification(id: UUID(), type: .promo, name: "优惠活动", time: "昨天", content: "春装上新季，全场满199减30，会员专享额外9折优惠", action: "立即领取"),
        UserNotification(id: UUID(), type: .sys, name: "系统消息", time: "3-25", content: "您的账号已成功绑定手机号，安全等级提升", action: ""),
        UserNotification(id: UUID(), type: .order, name: "订单提醒", time: "3-24", content: "您有一笔待支付订单即将过期，请尽快完成支付", action: "立即支付"),
    ]

    // MARK: - UserDefaults Keys
    private static let favoritesKey = "user_favorites"
    private static let historyKey = "user_history"
    private static let searchHistoryKey = "user_search_history"

    // MARK: - Persistence
    private static func loadFavorites() -> [FavoriteProduct] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let items = try? JSONDecoder().decode([FavoriteProduct].self, from: data) else {
            return mockFavorites
        }
        return items
    }

    private static func saveFavorites(_ items: [FavoriteProduct]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }

    private static func loadHistory() -> [HistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return mockHistory
        }
        return items
    }

    private static func saveHistory(_ items: [HistoryItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private static func loadSearchHistory() -> [String] {
        UserDefaults.standard.stringArray(forKey: searchHistoryKey) ?? []
    }

    private static func saveSearchHistory(_ items: [String]) {
        UserDefaults.standard.set(items, forKey: searchHistoryKey)
    }

    // MARK: - API Methods (async with mock delay)
    private static func mockRequest<T>(_ data: T, delay: UInt64 = 300_000_000) async -> T {
        try? await Task.sleep(nanoseconds: delay)
        return data
    }

    // MARK: - Address API
    static func getAddresses() async -> [Address] {
        await mockRequest(mockAddresses)
    }

    static func getAddress(by id: UUID) async -> Address? {
        await mockRequest(mockAddresses.first { $0.id == id })
    }

    static func createAddress(_ address: Address) async -> Bool {
        await mockRequest(true)
    }

    static func updateAddress(_ address: Address) async -> Bool {
        await mockRequest(true)
    }

    static func deleteAddress(id: UUID) async -> Bool {
        await mockRequest(true)
    }

    static func setDefaultAddress(id: UUID) async -> Bool {
        await mockRequest(true)
    }

    // MARK: - Favorites API
    static func getFavorites() async -> [FavoriteProduct] {
        await mockRequest(loadFavorites())
    }

    static func isFavorited(productId: UUID) async -> Bool {
        let favorites = loadFavorites()
        return await mockRequest(favorites.contains { $0.id == productId })
    }

    static func addFavorite(_ product: Product) async -> Bool {
        var favorites = loadFavorites()
        if !favorites.contains(where: { $0.id == product.id }) {
            let item = FavoriteProduct(
                id: product.id,
                name: product.name,
                price: product.price,
                originalPrice: product.originalPrice,
                imageName: product.imageName,
                sales: product.formattedSalesCount
            )
            favorites.insert(item, at: 0)
            saveFavorites(favorites)
        }
        return await mockRequest(true)
    }

    static func removeFavorite(id: UUID) async -> Bool {
        var favorites = loadFavorites()
        favorites.removeAll { $0.id == id }
        saveFavorites(favorites)
        return await mockRequest(true)
    }

    static func toggleFavorite(_ product: Product) async -> Bool {
        var favorites = loadFavorites()
        if let index = favorites.firstIndex(where: { $0.id == product.id }) {
            favorites.remove(at: index)
            saveFavorites(favorites)
            return await mockRequest(false)
        } else {
            let item = FavoriteProduct(
                id: product.id,
                name: product.name,
                price: product.price,
                originalPrice: product.originalPrice,
                imageName: product.imageName,
                sales: product.formattedSalesCount
            )
            favorites.insert(item, at: 0)
            saveFavorites(favorites)
            return await mockRequest(true)
        }
    }

    // MARK: - History API
    static func getHistory() async -> [HistoryItem] {
        await mockRequest(loadHistory())
    }

    static func addHistory(_ product: Product) async -> Bool {
        var history = loadHistory()
        history.removeAll { $0.id == product.id }
        let item = HistoryItem(
            id: product.id,
            name: product.name,
            price: product.price,
            imageName: product.imageName,
            time: "刚刚"
        )
        history.insert(item, at: 0)
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
        saveHistory(history)
        return await mockRequest(true)
    }

    static func removeHistory(id: UUID) async -> Bool {
        var history = loadHistory()
        history.removeAll { $0.id == id }
        saveHistory(history)
        return await mockRequest(true)
    }

    static func clearHistory() async -> Bool {
        saveHistory([])
        return await mockRequest(true)
    }

    // MARK: - Search History API
    static func getSearchHistory() async -> [String] {
        await mockRequest(loadSearchHistory())
    }

    static func addSearchHistory(_ term: String) async -> Bool {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        var history = loadSearchHistory()
        history.removeAll { $0 == term }
        history.insert(term, at: 0)
        saveSearchHistory(Array(history.prefix(20)))
        return await mockRequest(true)
    }

    static func removeSearchHistory(_ term: String) async -> Bool {
        var history = loadSearchHistory()
        history.removeAll { $0 == term }
        saveSearchHistory(history)
        return await mockRequest(true)
    }

    static func clearSearchHistory() async -> Bool {
        saveSearchHistory([])
        return await mockRequest(true)
    }

    // MARK: - Coupon API
    static func getCoupons() async -> (available: [UserCoupon], used: [UserCoupon], expired: [UserCoupon]) {
        await mockRequest(mockCoupons)
    }

    static func claimCoupon(id: UUID) async -> Bool {
        await mockRequest(true)
    }

    // MARK: - Notification API
    static func getNotifications() async -> [UserNotification] {
        await mockRequest(mockNotifications)
    }

    static func getNotifications(type: UserNotification.NotificationType) async -> [UserNotification] {
        if type == .order {
            return await mockRequest(mockNotifications.filter { $0.type == .order })
        }
        return await mockRequest(mockNotifications)
    }

    static func getUnreadCount() async -> Int {
        await mockRequest(3)
    }

    static func markRead(id: UUID) async -> Bool {
        await mockRequest(true)
    }

    static func markAllRead() async -> Bool {
        await mockRequest(true)
    }
}

// MARK: - Codable conformance for persistence
extension FavoriteProduct: Codable {}
extension HistoryItem: Codable {}
