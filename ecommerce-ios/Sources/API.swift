import Foundation

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case networkError(Error)
    case unauthorized
    case serverError(code: Int, message: String)
    case decodingError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .unauthorized:
            return "未授权，请重新登录"
        case .serverError(_, let message):
            return message
        case .decodingError(let error):
            #if DEBUG
            return "数据解析错误: \(error.localizedDescription)"
            #else
            return "数据解析错误"
            #endif
        case .unknown:
            return "未知错误"
        }
    }
}

func userFacingErrorMessage(_ error: Error, fallback: String) -> String {
    if let message = (error as? LocalizedError)?.errorDescription, !message.isEmpty {
        return message
    }
    return fallback
}

extension Decimal {
    var rmbText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? "¥" + NSDecimalNumber(decimal: self).stringValue
    }
}

// MARK: - API Endpoints

enum APIEndpoints {
    // Auth
    static let login = "login/"

    // Products
    static let products = "products/"
    static func product(_ id: String) -> String { "products/\(id)" }
    static func productReviews(_ id: String) -> String { "products/\(id)/reviews/" }
    static func searchProducts(q: String) -> String { "products/search/?q=\(q)" }

    // Categories
    static let categories = "categories/"
    static func category(_ id: String) -> String { "categories/\(id)/" }
    static func categoryProducts(_ id: String) -> String { "categories/\(id)/products/" }

    // Home
    static let homeBanners = "home/banners/"
    static let homeFlashSales = "home/flash-sales/"
    static let homeHotRanks = "home/hot-ranks/"
    static let homeRecommends = "home/recommends/"
    static let homeNewArrivals = "home/new-arrivals/"

    // Cart
    static let cart = "cart/"
    static func cartItem(_ id: String) -> String { "cart/\(id)/" }
    static func cartToggle(_ id: String) -> String { "cart/\(id)/toggle/" }
    static let cartSelectAll = "cart/select_all/"
    static let cartClear = "cart/clear/"

    // Orders
    static let orders = "orders/"
    static let orderPreview = "orders/preview/"
    static func order(_ id: String) -> String { "orders/\(id)/" }
    static func orderCancel(_ id: String) -> String { "orders/\(id)/cancel/" }
    static func orderPay(_ id: String) -> String { "orders/\(id)/pay/" }
    static func orderShip(_ id: String) -> String { "orders/\(id)/ship/" }
    static func orderLogistics(_ id: String) -> String { "orders/\(id)/logistics/" }
    static func orderConfirm(_ id: String) -> String { "orders/\(id)/confirm/" }
    static func orderAfterSale(_ id: String) -> String { "orders/\(id)/after-sale/" }
    static func orderBuyAgain(_ id: String) -> String { "orders/\(id)/buy-again/" }
    static func payment(_ id: String) -> String { "payments/\(id)/" }
    static func paymentConfirm(_ id: String) -> String { "payments/\(id)/confirm/" }

    // Addresses
    static let addresses = "addresses/"
    static let addressRegion = "addresses/region/"
    static func address(_ id: String) -> String { "addresses/\(id)/" }
    static func addressSetDefault(_ id: String) -> String { "addresses/\(id)/set_default/" }

    // Favorites
    static let favorites = "favorites/"
    static func favoriteItem(_ id: String) -> String { "favorites/\(id)/" }
    static func favoritesCheck(productId: String) -> String { "favorites/check/?product_id=\(productId)" }

    // Browse History
    static let browseHistory = "browse-history/"
    static func browseHistoryItem(_ id: String) -> String { "browse-history/\(id)/" }
    static let browseHistoryClear = "browse-history/clear/"

    // Coupons
    static let coupons = "coupons/"

    // Notifications
    static let notifications = "notifications/"
    static let notificationReadAll = "notifications/read_all/"
    static func notificationRead(_ id: String) -> String { "notifications/\(id)/read/" }

    // User
    static let userProfile = "user/profile/"

    // VIP & Shop
    static let vip = "vip/"
    static let vipUpgrade = "vip/upgrade/"
    static let shopInfo = "shop/"
}

enum APIEncoding {
    static func queryValue(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}

// MARK: - API Client

@MainActor
final class APIClient {
    static let shared = APIClient()

    // Debug targets the local Django API; release targets the hosted API.
    private let baseURL: String

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        #if DEBUG
        self.baseURL = "http://localhost:8080/api/h5"
        #else
        self.baseURL = "https://handsome-youth-production-98c5.up.railway.app/api/h5"
        #endif

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Token

    var token: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set {
            if let v = newValue {
                UserDefaults.standard.set(v, forKey: "auth_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "auth_token")
            }
        }
    }

    var isAuthenticated: Bool {
        token != nil && !token!.isEmpty
    }

    // MARK: - Request Building

    private func buildRequest(
        endpoint: String,
        method: String,
        body: Data? = nil,
        requiresAuth: Bool = false
    ) throws -> URLRequest {
        let urlString = "\(baseURL)/\(endpoint)"
        guard let url = URL(string: urlString) else {
            throw APIError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            guard let t = token else {
                throw APIError.unauthorized
            }
            request.setValue("Token \(t)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        return request
    }

    // MARK: - Raw Request

    private func rawRequest(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws -> Data {
        var bodyData: Data? = nil
        if let body = body {
            bodyData = try encoder.encode(body)
        }

        let request = try buildRequest(
            endpoint: endpoint,
            method: method,
            body: bodyData,
            requiresAuth: requiresAuth
        )

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }

            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw APIError.unauthorized
            default:
                let message = serverErrorMessage(from: data) ?? "服务器错误"
                throw APIError.serverError(code: httpResponse.statusCode, message: message)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func serverErrorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        return extractMessage(from: object)
    }

    private func extractMessage(from object: Any) -> String? {
        if let message = object as? String {
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        if let messages = object as? [String] {
            return messages
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
        }

        if let dict = object as? [String: Any] {
            for key in ["msg", "message", "detail", "error"] {
                if let message = extractMessage(from: dict[key] as Any) {
                    return message
                }
            }

            for (_, value) in dict {
                if let message = extractMessage(from: value) {
                    return message
                }
            }
        }

        if let list = object as? [Any] {
            for value in list {
                if let message = extractMessage(from: value) {
                    return message
                }
            }
        }

        return nil
    }

    // MARK: - Generic Request with Envelope

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        let data = try await rawRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )

        do {
            let envelope = try decoder.decode(ResponseEnvelope<T>.self, from: data)
            guard envelope.code == 0 else {
                throw APIError.serverError(code: envelope.code, message: envelope.msg)
            }
            guard let responseData = envelope.data else {
                throw APIError.serverError(code: envelope.code, message: "响应数据为空")
            }
            return responseData
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Request without expecting data (DELETE, etc.)

    func requestNoData(
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws {
        _ = try await rawRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
    }

    // MARK: - Auth

    struct LoginRequest: Encodable {
        let username: String
        let password: String
    }

    struct LoginResponse: Decodable {
        let token: String
        let userType: String

        enum CodingKeys: String, CodingKey {
            case token
            case userType = "user_type"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            token = try container.decode(String.self, forKey: .token)
            userType = try container.decode(String.self, forKey: .userType)
        }
    }

    func login(username: String, password: String) async throws -> LoginResponse {
        let body = LoginRequest(username: username, password: password)
        let resp: LoginResponse = try await request(
            endpoint: APIEndpoints.login,
            method: "POST",
            body: body,
            requiresAuth: false
        )
        self.token = resp.token
        return resp
    }

    func logout() {
        token = nil
    }
}

// MARK: - Response Envelope

private struct ResponseEnvelope<T: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: T?
}
