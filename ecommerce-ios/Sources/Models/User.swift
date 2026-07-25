import Foundation

// MARK: - User Profile Response from Backend
struct UserProfile: Codable {
    let id: Int
    let username: String
    let email: String
    let avatarName: String
    let phone: String?
    let phoneMasked: String?
    let gender: String?
    let genderLabel: String?
    let birthday: String?
    let registeredAt: String?
    let followCount: Int?
    let fansCount: Int?
    let points: Int?
    let vipLevel: String?
    let vipLevelName: String?
    let vipExpireDate: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case avatarName = "avatar_name"
        case phone
        case phoneMasked = "phone_masked"
        case gender
        case genderLabel = "gender_label"
        case birthday
        case registeredAt = "registered_at"
        case followCount, fansCount, points
        case vipLevel = "vip_level"
        case vipLevelName = "vip_level_name"
        case vipExpireDate = "vip_expire_date"
    }
}

// MARK: - User Model
struct User: Identifiable {
    let id: Int
    let name: String
    let email: String
    let avatarName: String
    let phone: String
    let phoneMasked: String
    let gender: String
    let genderLabel: String
    let birthday: String
    let registeredAt: String
    let followCount: Int
    let fansCount: Int
    let points: Int
    let vipLevel: String
    let vipLevelName: String
    let vipExpireDate: String?
}

// MARK: - VIP Info
struct VIPInfo: Codable {
    let level: String
    let levelName: String
    let expireDate: String?
    let points: Int
    let growthValue: Int
    let nextLevel: String?
    let nextLevelName: String?

    enum CodingKeys: String, CodingKey {
        case level
        case levelName = "level_name"
        case expireDate = "expire_date"
        case points
        case growthValue = "growth_value"
        case nextLevel = "next_level"
        case nextLevelName = "next_level_name"
    }

    var isMaxLevel: Bool { nextLevel == nil }
}

// MARK: - Shop Info
struct ShopInfo: Codable {
    let name: String
    let description: String
    let score: String
    let productCount: Int
    let sales: String
    let fansCount: String

    enum CodingKeys: String, CodingKey {
        case name, description, score, sales
        case productCount = "product_count"
        case fansCount = "fans_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "潮流优品官方旗舰店"
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        if let scoreText = try? container.decode(String.self, forKey: .score) {
            score = scoreText
        } else if let scoreValue = try? container.decode(Double.self, forKey: .score) {
            score = String(format: "%.1f", scoreValue)
        } else {
            score = "4.9"
        }
        productCount = try container.decodeIfPresent(Int.self, forKey: .productCount) ?? 0
        sales = try container.decodeIfPresent(String.self, forKey: .sales) ?? "0"
        fansCount = try container.decodeIfPresent(String.self, forKey: .fansCount) ?? "0"
    }
}

// MARK: - Address model
struct Address: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let phone: String
    let province: String
    let city: String
    let district: String
    let detail: String
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, phone, province, city, district, detail
        case isDefault = "is_default"
    }

    var fullAddress: String {
        "\(province) \(city) \(district) \(detail)"
    }
}

// MARK: - Favorite Product (simplified for list display)
struct FavoriteProduct: Identifiable, Codable {
    let id: String
    let name: String
    let price: Decimal
    let originalPrice: Decimal?
    let image: String?
    let sales: String

    var imageURL: URL? {
        guard let image else { return nil }
        return URL(string: image)
    }

    var asProduct: Product {
        Product(
            id: id,
            name: name,
            description: "",
            price: price,
            originalPrice: originalPrice,
            image: image ?? "",
            subcategoryRef: nil,
            rating: 5,
            reviewCount: 0,
            salesCount: Int(sales.filter(\.isNumber)) ?? 0,
            isInStock: true,
            tag: ""
        )
    }
}

// MARK: - Browse History Item
struct HistoryItem: Identifiable, Codable {
    let id: String
    let product: Product
    let viewedAt: String
    let time: String

    enum CodingKeys: String, CodingKey {
        case id, product, time
        case viewedAt = "viewed_at"
    }

    var displayTime: String {
        if !time.isEmpty { return time }
        return String(viewedAt.prefix(16)).replacingOccurrences(of: "T", with: " ")
    }
}

// MARK: - Notification Model (for user notifications)
struct UserNotification: Identifiable, Codable {
    let id: String
    let type: String
    let name: String
    let time: String
    let content: String
    let action: String
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id, type, name, time, content, action
        case isRead = "is_read"
    }
}

// MARK: - UserCoupon model (for user coupons)
struct UserCoupon: Identifiable, Codable {
    let id: String
    let name: String
    let value: Decimal
    let threshold: String  // Original string like "满100元减20元"
    let thresholdAmount: Int  // Numeric value for comparison
    let description: String
    let time: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, name, value, threshold, description, time, status
        case thresholdAmount = "threshold_amount"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        if let decimal = try? container.decode(Decimal.self, forKey: .value) {
            value = decimal
        } else if let string = try? container.decode(String.self, forKey: .value), let decimal = Decimal(string: string) {
            value = decimal
        } else {
            value = Decimal(try container.decode(Int.self, forKey: .value))
        }
        threshold = try container.decode(String.self, forKey: .threshold)
        thresholdAmount = try container.decodeIfPresent(Int.self, forKey: .thresholdAmount) ?? 0
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        time = try container.decodeIfPresent(String.self, forKey: .time) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "available"
    }

    var discountValue: Int { Int(truncating: value as NSDecimalNumber) }
}

// MARK: - User API
extension User {
    static func getProfile() async throws -> User {
        let profile: UserProfile = try await APIClient.shared.request(
            endpoint: APIEndpoints.userProfile,
            requiresAuth: true
        )
        return User(
            id: profile.id,
            name: profile.username,
            email: profile.email,
            avatarName: profile.avatarName,
            phone: profile.phone ?? "",
            phoneMasked: profile.phoneMasked ?? "",
            gender: profile.gender ?? "secret",
            genderLabel: profile.genderLabel ?? "保密",
            birthday: profile.birthday ?? "",
            registeredAt: profile.registeredAt ?? "",
            followCount: profile.followCount ?? 0,
            fansCount: profile.fansCount ?? 0,
            points: profile.points ?? 0,
            vipLevel: profile.vipLevel ?? "none",
            vipLevelName: profile.vipLevelName ?? "普通会员",
            vipExpireDate: profile.vipExpireDate
        )
    }

    static func updateProfile(
        username: String,
        email: String,
        phone: String,
        gender: String,
        birthday: String,
        avatar: String? = nil
    ) async throws -> User {
        struct UpdateRequest: Encodable {
            let username: String
            let email: String
            let phone: String
            let gender: String
            let birthday: String
            let avatar: String?
        }
        let profile: UserProfile = try await APIClient.shared.request(
            endpoint: APIEndpoints.userProfile,
            method: "PATCH",
            body: UpdateRequest(
                username: username,
                email: email,
                phone: phone,
                gender: gender,
                birthday: birthday,
                avatar: avatar
            ),
            requiresAuth: true
        )
        return User(
            id: profile.id,
            name: profile.username,
            email: profile.email,
            avatarName: profile.avatarName,
            phone: profile.phone ?? "",
            phoneMasked: profile.phoneMasked ?? "",
            gender: profile.gender ?? "secret",
            genderLabel: profile.genderLabel ?? "保密",
            birthday: profile.birthday ?? "",
            registeredAt: profile.registeredAt ?? "",
            followCount: profile.followCount ?? 0,
            fansCount: profile.fansCount ?? 0,
            points: profile.points ?? 0,
            vipLevel: profile.vipLevel ?? "none",
            vipLevelName: profile.vipLevelName ?? "普通会员",
            vipExpireDate: profile.vipExpireDate
        )
    }

    static func updateProfile(username: String, email: String) async throws {
        _ = try await updateProfile(
            username: username,
            email: email,
            phone: "",
            gender: "secret",
            birthday: ""
        )
    }
}

extension Address {
    static func getRegion() async throws -> [String: [String: [String]]] {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.addressRegion,
            requiresAuth: true
        )
    }

    static func getAddresses() async throws -> [Address] {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.addresses,
            requiresAuth: true
        )
    }

    static func createAddress(_ address: Address) async throws {
        struct CreateRequest: Encodable {
            let name: String; let phone: String; let province: String
            let city: String; let district: String; let detail: String; let isDefault: Bool
            enum CodingKeys: String, CodingKey {
                case name, phone, province, city, district, detail
                case isDefault = "is_default"
            }
        }
        _ = try await APIClient.shared.request(
            endpoint: APIEndpoints.addresses,
            method: "POST",
            body: CreateRequest(
                name: address.name, phone: address.phone,
                province: address.province, city: address.city,
                district: address.district, detail: address.detail,
                isDefault: address.isDefault
            ),
            requiresAuth: true
        ) as Address
    }

    static func updateAddress(_ address: Address) async throws {
        struct UpdateRequest: Encodable {
            let name: String; let phone: String; let province: String
            let city: String; let district: String; let detail: String; let isDefault: Bool
            enum CodingKeys: String, CodingKey {
                case name, phone, province, city, district, detail
                case isDefault = "is_default"
            }
        }
        _ = try await APIClient.shared.request(
            endpoint: APIEndpoints.address(address.id),
            method: "PUT",
            body: UpdateRequest(
                name: address.name, phone: address.phone,
                province: address.province, city: address.city,
                district: address.district, detail: address.detail,
                isDefault: address.isDefault
            ),
            requiresAuth: true
        ) as Address
    }

    static func deleteAddress(id: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.address(id),
            method: "DELETE",
            requiresAuth: true
        )
    }

    static func setDefaultAddress(id: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.addressSetDefault(id),
            method: "PUT",
            requiresAuth: true
        )
    }
}

extension FavoriteProduct {
    static func getFavorites() async throws -> [FavoriteProduct] {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.favorites,
            requiresAuth: true
        )
    }

    static func addFavorite(productId: String) async throws -> String {
        struct AddRequest: Encodable { let productId: String }
        struct AddResponse: Decodable { let id: String }
        let resp: AddResponse = try await APIClient.shared.request(
            endpoint: APIEndpoints.favorites,
            method: "POST",
            body: AddRequest(productId: productId),
            requiresAuth: true
        )
        return resp.id
    }

    static func removeFavorite(id: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: "\(APIEndpoints.favorites)\(id)/",
            method: "DELETE",
            requiresAuth: true
        )
    }

    struct CheckResult: Decodable {
        let isFavorited: Bool
        let favoriteId: String?
        enum CodingKeys: String, CodingKey {
            case isFavorited = "is_favorited"
            case favoriteId = "favorite_id"
        }
    }

    static func checkFavorite(productId: String) async throws -> CheckResult {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.favoritesCheck(productId: productId),
            requiresAuth: true
        )
    }
}

extension HistoryItem {
    static func getHistory() async throws -> [HistoryItem] {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.browseHistory,
            requiresAuth: true
        )
    }

    static func add(productId: String) async throws {
        struct AddRequest: Encodable { let productId: String }
        _ = try await APIClient.shared.request(
            endpoint: APIEndpoints.browseHistory,
            method: "POST",
            body: AddRequest(productId: productId),
            requiresAuth: true
        ) as HistoryItem
    }

    static func remove(id: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.browseHistoryItem(id),
            method: "DELETE",
            requiresAuth: true
        )
    }

    static func clear() async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.browseHistoryClear,
            method: "DELETE",
            requiresAuth: true
        )
    }
}

extension UserNotification {
    static func getNotifications() async throws -> [UserNotification] {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.notifications,
            requiresAuth: true
        )
    }

    static func markRead(id: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: "\(APIEndpoints.notifications)\(id)/read/",
            method: "PUT",
            requiresAuth: true
        )
    }

    static func markAllRead() async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.notificationReadAll,
            method: "PUT",
            requiresAuth: true
        )
    }

    static func getUnreadCount() async throws -> Int {
        struct CountResponse: Codable { let count: Int }
        let resp: CountResponse = try await APIClient.shared.request(
            endpoint: "\(APIEndpoints.notifications)count/",
            requiresAuth: true
        )
        return resp.count
    }
}

extension UserCoupon {
    static func getCoupons() async throws -> [UserCoupon] {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.coupons,
            requiresAuth: true
        )
    }
}

extension VIPInfo {
    static func getVIP() async throws -> VIPInfo {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.vip,
            requiresAuth: true
        )
    }

    static func upgrade() async throws -> VIPInfo {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.vipUpgrade,
            method: "POST",
            requiresAuth: true
        )
    }
}

extension ShopInfo {
    static func getInfo() async throws -> ShopInfo {
        try await APIClient.shared.request(endpoint: APIEndpoints.shopInfo, requiresAuth: false)
    }

    static func getProducts() async throws -> [Product] {
        try await Product.getProducts()
    }
}
