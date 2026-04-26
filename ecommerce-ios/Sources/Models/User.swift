import Foundation

// MARK: - User Profile Response from Backend
struct UserProfile: Codable {
    let id: Int
    let username: String
    let email: String
    let avatarName: String
    let followCount: Int?
    let fansCount: Int?
    let points: Int?

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case avatarName = "avatar_name"
        case followCount, fansCount, points
    }
}

// MARK: - User Model
struct User: Identifiable {
    let id: Int
    let name: String
    let email: String
    let avatarName: String
}

// MARK: - Address model
struct Address: Identifiable, Codable {
    let id: String
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
struct FavoriteProduct: Identifiable, Codable {
    let id: String
    let name: String
    let price: Decimal
    let originalPrice: Decimal?
    let image: String
    let sales: String

    var imageURL: URL? { URL(string: image) }
}

// MARK: - Browse History Item
struct HistoryItem: Identifiable, Codable {
    let id: String
    let name: String
    let price: Decimal
    let imageName: String
    let time: String
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
}

// MARK: - UserCoupon model (for user coupons)
struct UserCoupon: Identifiable, Codable {
    let id: String
    let name: String
    let value: Decimal
    let threshold: Decimal
    let description: String
    let time: String

    var discountValue: Int { Int(truncating: value as NSDecimalNumber) }
    var thresholdValue: Int { Int(truncating: threshold as NSDecimalNumber) }
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
            avatarName: profile.avatarName
        )
    }
}

extension Address {
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
        ) as EmptyResponse
    }

    static func updateAddress(_ address: Address) async throws {
        struct UpdateRequest: Encodable {
            let name: String; let phone: String; let province: String
            let city: String; let district: String; let detail: String; let isDefault: Bool
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
        ) as EmptyResponse
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

    static func addFavorite(productId: String) async throws {
        struct AddRequest: Encodable { let productId: String }
        _ = try await APIClient.shared.request(
            endpoint: APIEndpoints.favorites,
            method: "POST",
            body: AddRequest(productId: productId),
            requiresAuth: true
        ) as EmptyResponse
    }

    static func removeFavorite(id: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: "\(APIEndpoints.favorites)\(id)/",
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
