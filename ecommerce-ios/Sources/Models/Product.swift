import Foundation
import SwiftUI

// MARK: - Product Model
struct Product: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String
    let price: Decimal
    let originalPrice: Decimal?
    let image: String
    let subcategoryRef: SubcategoryRef?
    let rating: Double
    let reviewCount: Int
    let salesCount: Int
    let isInStock: Bool
    let tag: String

    // Custom CodingKeys to map backend JSON fields
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case price
        case originalPrice = "original_price"
        case image
        case subcategory
        case rating
        case reviewCount = "review_count"
        case salesCount = "sales_count"
        case isInStock = "is_in_stock"
        case tag
    }

    var imageURL: URL? { URL(string: image) }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)

        // Price can be string or number from backend
        if let priceStr = try? container.decode(String.self, forKey: .price) {
            price = Decimal(string: priceStr) ?? 0
        } else {
            price = try container.decode(Decimal.self, forKey: .price)
        }

        // Original price can be string, number, or null
        if let originalStr = try? container.decode(String.self, forKey: .originalPrice) {
            originalPrice = Decimal(string: originalStr)
        } else if let originalNum = try? container.decode(Double.self, forKey: .originalPrice) {
            originalPrice = Decimal(originalNum)
        } else {
            originalPrice = nil
        }

        image = try container.decode(String.self, forKey: .image)

        // Rating can be string or number from backend
        if let ratingStr = try? container.decode(String.self, forKey: .rating) {
            rating = Double(ratingStr) ?? 0
        } else {
            rating = try container.decode(Double.self, forKey: .rating)
        }

        // Review count can be string or number
        if let rcStr = try? container.decode(String.self, forKey: .reviewCount) {
            reviewCount = Int(rcStr) ?? 0
        } else {
            reviewCount = try container.decode(Int.self, forKey: .reviewCount)
        }

        // Sales count can be string or number
        if let scStr = try? container.decode(String.self, forKey: .salesCount) {
            salesCount = Int(scStr) ?? 0
        } else {
            salesCount = try container.decode(Int.self, forKey: .salesCount)
        }
        isInStock = try container.decode(Bool.self, forKey: .isInStock)
        tag = try container.decode(String.self, forKey: .tag)

        // Parse subcategory from backend
        subcategoryRef = try container.decodeIfPresent(SubcategoryRef.self, forKey: .subcategory)
    }

    // Encoder for sending data (if needed)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode("\(price)", forKey: .price)
        if let orig = originalPrice {
            try container.encode("\(orig)", forKey: .originalPrice)
        }
        try container.encode(image, forKey: .image)
        try container.encode(rating, forKey: .rating)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(salesCount, forKey: .salesCount)
        try container.encode(isInStock, forKey: .isInStock)
        try container.encode(tag, forKey: .tag)
    }

    // Manual initializer for previews/testing
    init(
        id: String,
        name: String,
        description: String,
        price: Decimal,
        originalPrice: Decimal?,
        image: String,
        subcategoryRef: SubcategoryRef?,
        rating: Double,
        reviewCount: Int,
        salesCount: Int,
        isInStock: Bool,
        tag: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.originalPrice = originalPrice
        self.image = image
        self.subcategoryRef = subcategoryRef
        self.rating = rating
        self.reviewCount = reviewCount
        self.salesCount = salesCount
        self.isInStock = isInStock
        self.tag = tag
    }

    var discount: Int? {
        guard let original = originalPrice, original > price else { return nil }
        let diff = NSDecimalNumber(decimal: original - price).doubleValue
        let originalValue = NSDecimalNumber(decimal: original).doubleValue
        return Int((diff / originalValue * 100).rounded())
    }

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "¥\(price)"
    }

    var formattedOriginalPrice: String? {
        guard let original = originalPrice else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSDecimalNumber(decimal: original))
    }

    var formattedSalesCount: String {
        if salesCount >= 10000 {
            return String(format: "%.1f万+", Double(salesCount) / 10000.0)
        } else if salesCount >= 1000 {
            return String(format: "%.1f千+", Double(salesCount) / 1000.0)
        }
        return "\(salesCount)+"
    }

    var salesCountText: String {
        return "已售 " + formattedSalesCount
    }
}

// MARK: - Category Model
struct Category: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let iconName: String
    let bannerName: String
    let subcategories: [String]

    enum CodingKeys: String, CodingKey {
        case id, name
        case iconName = "icon"
        case bannerName = "banner"
        case subcategories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? ""
        bannerName = try container.decodeIfPresent(String.self, forKey: .bannerName) ?? ""
        subcategories = try container.decodeIfPresent([String].self, forKey: .subcategories) ?? []
    }

    // Manual initializer for static all array
    init(id: String, name: String, iconName: String, bannerName: String, subcategories: [String]) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.bannerName = bannerName
        self.subcategories = subcategories
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(bannerName, forKey: .bannerName)
        try container.encode(subcategories, forKey: .subcategories)
    }

    static let all: [Category] = [
        Category(id: "cat_women", name: "女装", iconName: "icon_fashion", bannerName: "https://picsum.photos/600/200?random=201", subcategories: ["T恤", "连衣裙", "牛仔裤", "外套", "衬衫", "半身裙"]),
        Category(id: "cat_men", name: "男装", iconName: "icon_mens", bannerName: "https://picsum.photos/600/200?random=202", subcategories: ["T恤", "休闲裤", "牛仔裤", "外套", "衬衫", "卫衣"]),
        Category(id: "cat_skincare", name: "美妆护肤", iconName: "icon_skincare", bannerName: "https://picsum.photos/600/200?random=203", subcategories: ["护肤", "彩妆", "面膜", "洁面", "精华", "防晒"]),
        Category(id: "cat_digital", name: "数码电子", iconName: "icon_phone", bannerName: "https://picsum.photos/600/200?random=204", subcategories: ["手机", "耳机", "充电宝", "数据线", "键盘", "鼠标"]),
        Category(id: "cat_home", name: "家居生活", iconName: "icon_home", bannerName: "https://picsum.photos/600/200?random=205", subcategories: ["收纳", "清洁", "餐厨", "家纺", "装饰", "绿植"]),
        Category(id: "cat_sport", name: "运动户外", iconName: "icon_sport", bannerName: "https://picsum.photos/600/200?random=206", subcategories: ["运动鞋", "健身服", "球类", "泳装", "户外装备", "瑜伽"]),
        Category(id: "cat_food", name: "食品生鲜", iconName: "icon_food", bannerName: "https://picsum.photos/600/200?random=207", subcategories: ["水果", "零食", "粮油", "饮料", "肉禽", "海鲜"]),
        Category(id: "cat_accessories", name: "潮流配饰", iconName: "icon_beauty", bannerName: "https://picsum.photos/600/200?random=208", subcategories: ["腕表", "包袋", "围巾", "帽子", "饰品", "眼镜"]),
    ]
}

// Helper for decoding subcategory reference from backend
struct SubcategoryRef: Codable, Hashable, Equatable {
    let id: String
    let name: String
    let categoryId: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case categoryId = "category_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
    }

    init(id: String, name: String, categoryId: String? = nil) {
        self.id = id
        self.name = name
        self.categoryId = categoryId
    }
}

// MARK: - Banner Model
struct Banner: Identifiable, Hashable, Codable {
    let id: String
    let image: String
    let tag: String
    let title: String
    let actionTitle: String
    let gradientType: GradientType

    enum GradientType: Int, Hashable, Codable {
        case summer = 0
        case newArrival = 1
        case flashSale = 2
    }

    enum CodingKeys: String, CodingKey {
        case id, image, tag, title
        case actionTitle = "action_title"
        case gradientType = "gradient_type"
    }

    var imageURL: URL? { URL(string: image) }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        image = try container.decode(String.self, forKey: .image)
        tag = try container.decode(String.self, forKey: .tag)
        title = try container.decode(String.self, forKey: .title)
        actionTitle = try container.decode(String.self, forKey: .actionTitle)
        gradientType = try container.decode(GradientType.self, forKey: .gradientType)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(image, forKey: .image)
        try container.encode(tag, forKey: .tag)
        try container.encode(title, forKey: .title)
        try container.encode(actionTitle, forKey: .actionTitle)
        try container.encode(gradientType, forKey: .gradientType)
    }

    var gradientColors: [Color] {
        switch gradientType {
        case .summer:
            return [Color(red: 1.0, green: 0.27, blue: 0.23).opacity(1.0), Color(red: 1.0, green: 0.5, blue: 0.3)]
        case .newArrival:
            return [Color.blue.opacity(0.7), Color.purple.opacity(0.5)]
        case .flashSale:
            return [Color.orange.opacity(0.8), Color.red.opacity(0.6)]
        }
    }
}

// MARK: - CategoryPage Model
struct CategoryPage: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let iconName: String
    let bannerName: String
    let subcategories: [String]
    let products: [Product]
}

// MARK: - Product API
extension Product {
    // MARK: - API Methods
    static func getProducts(for category: Category? = nil) async throws -> [Product] {
        var products: [Product] = try await APIClient.shared.request(
            endpoint: APIEndpoints.products,
            requiresAuth: false
        )
        if let category = category {
            products = products.filter { $0.subcategoryRef?.categoryId == category.id }
        }
        return products
    }

    static func searchProducts(query: String) async throws -> [Product] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.searchProducts(q: encoded),
            requiresAuth: false
        )
    }

    static func getProduct(by id: String) async throws -> Product {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.product(id),
            requiresAuth: false
        )
    }

    static func getFeaturedProducts() async throws -> [Product] {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.products,
            requiresAuth: false
        )
    }

    static func getOnSaleProducts() async throws -> [Product] {
        return try await getProducts()
    }

    static func getBanners() async throws -> [Banner] {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.homeBanners,
            requiresAuth: false
        )
    }

    static func getFlashSaleProducts() async throws -> [Product] {
        let sections: [FlashSaleSection] = try await APIClient.shared.request(
            endpoint: APIEndpoints.homeFlashSales,
            requiresAuth: false
        )
        return sections.flatMap { $0.products }
    }

    static func getHotRankingProducts() async throws -> [Product] {
        let sections: [HotRankSection] = try await APIClient.shared.request(
            endpoint: APIEndpoints.homeHotRanks,
            requiresAuth: false
        )
        return sections.flatMap { $0.products }
    }

    static func getRecommendProducts() async throws -> [Product] {
        let sections: [RecommendSection] = try await APIClient.shared.request(
            endpoint: APIEndpoints.homeRecommends,
            requiresAuth: false
        )
        return sections.flatMap { $0.products }
    }

    static func getNewArrivalProducts() async throws -> [Product] {
        let sections: [NewArrivalSection] = try await APIClient.shared.request(
            endpoint: APIEndpoints.homeNewArrivals,
            requiresAuth: false
        )
        return sections.flatMap { $0.products }
    }

    static func getRelatedProducts(for productId: String? = nil) async throws -> [Product] {
        var products: [Product] = try await APIClient.shared.request(
            endpoint: APIEndpoints.products,
            requiresAuth: false
        )
        if let id = productId {
            products = products.filter { $0.id != id }
        }
        return Array(products.prefix(6))
    }

    static let categoryPages: [CategoryPage] = [
        CategoryPage(id: "cp_women", name: "女装", iconName: "icon_fashion", bannerName: "https://picsum.photos/600/200?random=201", subcategories: ["T恤", "连衣裙", "牛仔裤", "外套", "衬衫", "半身裙"], products: []),
        CategoryPage(id: "cp_men", name: "男装", iconName: "icon_mens", bannerName: "https://picsum.photos/600/200?random=202", subcategories: ["T恤", "休闲裤", "牛仔裤", "外套", "衬衫", "卫衣"], products: []),
        CategoryPage(id: "cp_skincare", name: "美妆护肤", iconName: "icon_skincare", bannerName: "https://picsum.photos/600/200?random=203", subcategories: ["护肤", "彩妆", "面膜", "洁面", "精华", "防晒"], products: []),
        CategoryPage(id: "cp_digital", name: "数码电子", iconName: "icon_phone", bannerName: "https://picsum.photos/600/200?random=204", subcategories: ["手机", "耳机", "充电宝", "数据线", "键盘", "鼠标"], products: []),
        CategoryPage(id: "cp_home", name: "家居生活", iconName: "icon_home", bannerName: "https://picsum.photos/600/200?random=205", subcategories: ["收纳", "清洁", "餐厨", "家纺", "装饰", "绿植"], products: []),
        CategoryPage(id: "cp_sport", name: "运动户外", iconName: "icon_sport", bannerName: "https://picsum.photos/600/200?random=206", subcategories: ["运动鞋", "健身服", "球类", "泳装", "户外装备", "瑜伽"], products: []),
        CategoryPage(id: "cp_food", name: "食品生鲜", iconName: "icon_food", bannerName: "https://picsum.photos/600/200?random=207", subcategories: ["水果", "零食", "粮油", "饮料", "肉禽", "海鲜"], products: []),
        CategoryPage(id: "cp_accessories", name: "潮流配饰", iconName: "icon_beauty", bannerName: "https://picsum.photos/600/200?random=208", subcategories: ["腕表", "包袋", "围巾", "帽子", "饰品", "眼镜"], products: []),
    ]
}

// MARK: - Home Section Response Models
struct FlashSaleSection: Codable {
    let id: String
    let title: String
    let subtitle: String?
    let products: [Product]
}

struct HotRankSection: Codable {
    let id: String
    let title: String
    let products: [Product]
}

struct RecommendSection: Codable {
    let id: String
    let title: String
    let products: [Product]
}

struct NewArrivalSection: Codable {
    let id: String
    let title: String
    let products: [Product]
}

// MARK: - Spec Models
struct SpecValue: Identifiable, Hashable, Codable {
    let id: String
    let value: String
    let image: String?
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, value, image
        case sortOrder = "sort_order"
    }

    var imageURL: URL? {
        guard let image = image else { return nil }
        return URL(string: image)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(value, forKey: .value)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(sortOrder, forKey: .sortOrder)
    }
}

struct SpecGroup: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let sortOrder: Int
    let values: [SpecValue]

    enum CodingKeys: String, CodingKey {
        case id, name
        case sortOrder = "sort_order"
        case values
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(values, forKey: .values)
    }
}

struct SKU: Identifiable, Hashable, Codable {
    let id: String
    let price: Decimal
    let originalPrice: Decimal?
    let stock: Int
    let image: String?
    let specValueIds: [String]

    enum CodingKeys: String, CodingKey {
        case id, price
        case originalPrice = "original_price"
        case stock, image
        case specValueIds = "spec_value_ids"
    }

    var imageURL: URL? {
        guard let image = image else { return nil }
        return URL(string: image)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)

        if let priceStr = try? container.decode(String.self, forKey: .price) {
            price = Decimal(string: priceStr) ?? 0
        } else {
            price = try container.decode(Decimal.self, forKey: .price)
        }

        if let originalStr = try? container.decode(String.self, forKey: .originalPrice) {
            originalPrice = Decimal(string: originalStr)
        } else if let originalNum = try? container.decode(Double.self, forKey: .originalPrice) {
            originalPrice = Decimal(originalNum)
        } else {
            originalPrice = nil
        }

        stock = try container.decode(Int.self, forKey: .stock)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        specValueIds = try container.decode([String].self, forKey: .specValueIds)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode("\(price)", forKey: .price)
        if let orig = originalPrice {
            try container.encode("\(orig)", forKey: .originalPrice)
        }
        try container.encode(stock, forKey: .stock)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(specValueIds, forKey: .specValueIds)
    }
}

// MARK: - Product Detail Response
struct ProductDetail: Codable {
    let id: String
    let name: String
    let description: String
    let price: Decimal
    let originalPrice: Decimal?
    let image: String
    let subcategoryRef: SubcategoryRef?
    let rating: Double
    let reviewCount: Int
    let salesCount: Int
    let isInStock: Bool
    let tag: String
    let detail: ProductDetailInfo?
    let specGroups: [SpecGroup]
    let skus: [SKU]

    enum CodingKeys: String, CodingKey {
        case id, name, description, price
        case originalPrice = "original_price"
        case image, subcategory
        case rating
        case reviewCount = "review_count"
        case salesCount = "sales_count"
        case isInStock = "is_in_stock"
        case tag, detail
        case specGroups = "spec_groups"
        case skus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)

        if let priceStr = try? container.decode(String.self, forKey: .price) {
            price = Decimal(string: priceStr) ?? 0
        } else {
            price = try container.decode(Decimal.self, forKey: .price)
        }

        if let originalStr = try? container.decode(String.self, forKey: .originalPrice) {
            originalPrice = Decimal(string: originalStr)
        } else if let originalNum = try? container.decode(Double.self, forKey: .originalPrice) {
            originalPrice = Decimal(originalNum)
        } else {
            originalPrice = nil
        }

        image = try container.decode(String.self, forKey: .image)
        subcategoryRef = try container.decodeIfPresent(SubcategoryRef.self, forKey: .subcategory)

        if let ratingStr = try? container.decode(String.self, forKey: .rating) {
            rating = Double(ratingStr) ?? 0
        } else {
            rating = try container.decode(Double.self, forKey: .rating)
        }

        if let rcStr = try? container.decode(String.self, forKey: .reviewCount) {
            reviewCount = Int(rcStr) ?? 0
        } else {
            reviewCount = try container.decode(Int.self, forKey: .reviewCount)
        }

        if let scStr = try? container.decode(String.self, forKey: .salesCount) {
            salesCount = Int(scStr) ?? 0
        } else {
            salesCount = try container.decode(Int.self, forKey: .salesCount)
        }

        isInStock = try container.decode(Bool.self, forKey: .isInStock)
        tag = try container.decode(String.self, forKey: .tag)
        detail = try container.decodeIfPresent(ProductDetailInfo.self, forKey: .detail)
        specGroups = try container.decodeIfPresent([SpecGroup].self, forKey: .specGroups) ?? []
        skus = try container.decodeIfPresent([SKU].self, forKey: .skus) ?? []
    }

    func toProduct() -> Product {
        Product(
            id: id,
            name: name,
            description: description,
            price: price,
            originalPrice: originalPrice,
            image: image,
            subcategoryRef: subcategoryRef,
            rating: rating,
            reviewCount: reviewCount,
            salesCount: salesCount,
            isInStock: isInStock,
            tag: tag
        )
    }

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "¥\(price)"
    }

    var imageURL: URL? { URL(string: image) }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode("\(price)", forKey: .price)
        if let orig = originalPrice {
            try container.encode("\(orig)", forKey: .originalPrice)
        }
        try container.encode(image, forKey: .image)
        try container.encode(rating, forKey: .rating)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(salesCount, forKey: .salesCount)
        try container.encode(isInStock, forKey: .isInStock)
        try container.encode(tag, forKey: .tag)
        try container.encodeIfPresent(detail, forKey: .detail)
        try container.encode(specGroups, forKey: .specGroups)
        try container.encode(skus, forKey: .skus)
    }
}

struct ProductDetailInfo: Codable {
    let shopName: String
    let shopLogo: String?
    let images: [String]
    let detailImages: [String]

    enum CodingKeys: String, CodingKey {
        case shopName = "shop_name"
        case shopLogo = "shop_logo"
        case images
        case detailImages = "detail_images"
    }

    var shopLogoURL: URL? {
        guard let logo = shopLogo else { return nil }
        return URL(string: logo)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shopName, forKey: .shopName)
        try container.encodeIfPresent(shopLogo, forKey: .shopLogo)
        try container.encode(images, forKey: .images)
        try container.encode(detailImages, forKey: .detailImages)
    }
}

// MARK: - Spec Available Response
struct SpecAvailableResponse: Codable {
    let groupId: String
    let availableValues: [String]

    enum CodingKeys: String, CodingKey {
        case groupId
        case availableValues
    }
}

// MARK: - Product API Extensions
extension Product {
    static func getDetail(id: String) async throws -> ProductDetail {
        return try await APIClient.shared.request(
            endpoint: APIEndpoints.product(id),
            requiresAuth: false
        )
    }

    static func getSpecAvailable(productId: String, selectedIds: [String]) async throws -> [SpecAvailableResponse] {
        let selectedStr = selectedIds.joined(separator: ",")
        let endpoint = "\(APIEndpoints.product(productId))/spec-available/?selected=\(selectedStr)"
        return try await APIClient.shared.request(
            endpoint: endpoint,
            requiresAuth: false
        )
    }
}
