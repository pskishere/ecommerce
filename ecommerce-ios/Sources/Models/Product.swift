import Foundation
import SwiftUI

// MARK: - Product Model
struct Product: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let price: Decimal
    let originalPrice: Decimal?
    let imageName: String
    let category: Category
    let rating: Double
    let reviewCount: Int
    let salesCount: Int
    let isInStock: Bool

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
struct Category: Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconName: String

    static let all: [Category] = [
        Category(id: UUID(), name: "女装", iconName: "icon_fashion"),
        Category(id: UUID(), name: "男装", iconName: "icon_mens"),
        Category(id: UUID(), name: "美妆护肤", iconName: "icon_skincare"),
        Category(id: UUID(), name: "数码电子", iconName: "icon_phone"),
        Category(id: UUID(), name: "家居生活", iconName: "icon_home"),
        Category(id: UUID(), name: "运动户外", iconName: "icon_sport"),
        Category(id: UUID(), name: "食品生鲜", iconName: "icon_food"),
        Category(id: UUID(), name: "潮流配饰", iconName: "icon_beauty"),
    ]
}

// MARK: - Banner Model
struct Banner: Identifiable, Hashable {
    let id: UUID
    let imageName: String
    let tag: String
    let title: String
    let actionTitle: String
    let gradientType: GradientType

    enum GradientType: Int, Hashable {
        case summer = 0
        case newArrival = 1
        case flashSale = 2
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
struct CategoryPage: Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let bannerName: String
    let subcategories: [String]
    let products: [Product]
}

// MARK: - Product API
extension Product {
    // MARK: - Mock Data
    static let flashSaleProducts: [Product] = [
        Product(id: UUID(), name: "时尚简约腕表", description: "经典设计，优质材料", price: 299, originalPrice: 899, imageName: "product_01_watch", category: Category.all[7], rating: 4.8, reviewCount: 1200, salesCount: 23000, isInStock: true),
        Product(id: UUID(), name: "无线蓝牙耳机", description: "主动降噪，高品质音效", price: 199, originalPrice: 499, imageName: "product_02_earbuds", category: Category.all[3], rating: 4.7, reviewCount: 890, salesCount: 18000, isInStock: true),
        Product(id: UUID(), name: "极简陶瓷咖啡杯", description: "简约设计，优质陶瓷", price: 39, originalPrice: 79, imageName: "product_03_mug", category: Category.all[4], rating: 4.6, reviewCount: 560, salesCount: 12000, isInStock: true),
        Product(id: UUID(), name: "有机护肤精华液", description: "深层补水，保湿滋养", price: 129, originalPrice: 399, imageName: "product_04_serum", category: Category.all[2], rating: 4.9, reviewCount: 2300, salesCount: 15000, isInStock: true),
        Product(id: UUID(), name: "经典帆布硫化鞋", description: "时尚百搭，舒适透气", price: 159, originalPrice: 359, imageName: "product_05_sneakers", category: Category.all[5], rating: 4.7, reviewCount: 1800, salesCount: 20000, isInStock: true),
    ]

    static let hotRankingProducts: [Product] = [
        Product(id: UUID(), name: "头层牛皮钱包", description: "真皮材质，经典款式", price: 189, originalPrice: nil, imageName: "product_06_wallet", category: Category.all[7], rating: 4.8, reviewCount: 1500, salesCount: 23000, isInStock: true),
        Product(id: UUID(), name: "复古飞行员太阳镜", description: "时尚复古，防晒实用", price: 129, originalPrice: nil, imageName: "product_07_sunglasses", category: Category.all[7], rating: 4.6, reviewCount: 980, salesCount: 18000, isInStock: true),
        Product(id: UUID(), name: "多肉植物盆栽", description: "可爱易养，净化空气", price: 49, originalPrice: nil, imageName: "product_08_plantpot", category: Category.all[4], rating: 4.5, reviewCount: 670, salesCount: 15000, isInStock: true),
        Product(id: UUID(), name: "手账笔记本 A5", description: "优质纸张，精致装订", price: 35, originalPrice: nil, imageName: "product_09_notebook", category: Category.all[4], rating: 4.7, reviewCount: 890, salesCount: 12000, isInStock: true),
    ]

    static let recommendedProducts: [Product] = [
        Product(id: UUID(), name: "天然香薰蜡烛 150g", description: "纯天然植物精油", price: 89, originalPrice: nil, imageName: "product_10_candle", category: Category.all[4], rating: 4.8, reviewCount: 1200, salesCount: 12000, isInStock: true),
        Product(id: UUID(), name: "文艺帆布托特包", description: "大容量，文艺风格", price: 59, originalPrice: nil, imageName: "product_11_tote", category: Category.all[7], rating: 4.7, reviewCount: 890, salesCount: 9800, isInStock: true),
        Product(id: UUID(), name: "不锈钢保温水瓶 750ml", description: "持久保温，保冷保热", price: 79, originalPrice: nil, imageName: "product_12_bottle", category: Category.all[5], rating: 4.9, reviewCount: 2100, salesCount: 8600, isInStock: true),
        Product(id: UUID(), name: "简约真皮腕表", description: "时尚简约，真皮表带", price: 299, originalPrice: nil, imageName: "product_01_watch", category: Category.all[7], rating: 4.8, reviewCount: 1200, salesCount: 23000, isInStock: true),
        Product(id: UUID(), name: "无线蓝牙耳机", description: "主动降噪，高品质音效", price: 199, originalPrice: nil, imageName: "product_02_earbuds", category: Category.all[3], rating: 4.7, reviewCount: 890, salesCount: 18000, isInStock: true),
        Product(id: UUID(), name: "头层牛皮短款钱包", description: "真皮材质，小巧实用", price: 189, originalPrice: nil, imageName: "product_06_wallet", category: Category.all[7], rating: 4.8, reviewCount: 1500, salesCount: 15000, isInStock: true),
    ]

    static let allProducts: [Product] = flashSaleProducts + hotRankingProducts + recommendedProducts

    static let banners: [Banner] = [
        Banner(id: UUID(), imageName: "banner_summer", tag: "限时特惠", title: "夏季焕新\n全场低至5折", actionTitle: "立即选购", gradientType: .summer),
        Banner(id: UUID(), imageName: "banner_new", tag: "新品首发", title: "当季新款\n潮流抢先穿", actionTitle: "查看全部", gradientType: .newArrival),
        Banner(id: UUID(), imageName: "banner_flash", tag: "今日疯抢", title: "爆款直降\n再享折上折", actionTitle: "马上抢", gradientType: .flashSale),
    ]

    static let categoryPages: [CategoryPage] = [
        CategoryPage(id: UUID(), name: "女装", iconName: "icon_fashion", bannerName: "banner_summer", subcategories: ["连衣裙", "T恤", "衬衫", "牛仔裤"], products: [
            Product(id: UUID(), name: "法式碎花连衣裙", description: "优雅碎花设计，夏季必备", price: 189, originalPrice: 259, imageName: "product_11_tote", category: Category.all[0], rating: 4.8, reviewCount: 1200, salesCount: 8500, isInStock: true),
            Product(id: UUID(), name: "纯棉宽松T恤", description: "舒适纯棉面料", price: 79, originalPrice: 99, imageName: "product_03_mug", category: Category.all[0], rating: 4.6, reviewCount: 800, salesCount: 12000, isInStock: true),
            Product(id: UUID(), name: "高腰直筒牛仔裤", description: "显瘦百搭款", price: 159, originalPrice: 199, imageName: "product_05_sneakers", category: Category.all[0], rating: 4.7, reviewCount: 650, salesCount: 5600, isInStock: true),
            Product(id: UUID(), name: "百褶半身长裙", description: "气质百褶设计", price: 139, originalPrice: 179, imageName: "product_01_watch", category: Category.all[0], rating: 4.5, reviewCount: 420, salesCount: 3200, isInStock: true),
        ]),
        CategoryPage(id: UUID(), name: "男装", iconName: "icon_mens", bannerName: "banner_new", subcategories: ["T恤", "衬衫", "裤装", "外套"], products: [
            Product(id: UUID(), name: "经典纯白T恤", description: "百搭基础款", price: 99, originalPrice: 129, imageName: "product_05_sneakers", category: Category.all[1], rating: 4.8, reviewCount: 1500, salesCount: 9800, isInStock: true),
            Product(id: UUID(), name: "休闲商务衬衫", description: "上班休闲两不误", price: 149, originalPrice: 199, imageName: "product_03_mug", category: Category.all[1], rating: 4.6, reviewCount: 780, salesCount: 4500, isInStock: true),
            Product(id: UUID(), name: "飞行员夹克", description: "时尚帅气", price: 299, originalPrice: 399, imageName: "product_11_tote", category: Category.all[1], rating: 4.9, reviewCount: 520, salesCount: 2800, isInStock: true),
        ]),
        CategoryPage(id: UUID(), name: "美妆护肤", iconName: "icon_skincare", bannerName: "banner_flash", subcategories: ["护肤", "彩妆", "香水", "个护"], products: [
            Product(id: UUID(), name: "玻尿酸保湿精华液", description: "深层补水保湿", price: 159, originalPrice: 219, imageName: "product_04_serum", category: Category.all[2], rating: 4.7, reviewCount: 2300, salesCount: 15000, isInStock: true),
            Product(id: UUID(), name: "氨基酸洁面乳", description: "温和清洁", price: 89, originalPrice: 119, imageName: "product_02_earbuds", category: Category.all[2], rating: 4.5, reviewCount: 1800, salesCount: 22000, isInStock: true),
            Product(id: UUID(), name: "经典女士香水", description: "优雅气质", price: 259, originalPrice: 329, imageName: "product_03_mug", category: Category.all[2], rating: 4.8, reviewCount: 920, salesCount: 5100, isInStock: true),
        ]),
        CategoryPage(id: UUID(), name: "数码电子", iconName: "icon_phone", bannerName: "banner_summer", subcategories: ["手机", "耳机", "音箱", "配件"], products: [
            Product(id: UUID(), name: "无线蓝牙耳机Pro", description: "主动降噪", price: 299, originalPrice: 399, imageName: "product_02_earbuds", category: Category.all[3], rating: 4.8, reviewCount: 4500, salesCount: 35000, isInStock: true),
            Product(id: UUID(), name: "便携蓝牙音箱", description: "小巧便携", price: 199, originalPrice: 259, imageName: "product_03_mug", category: Category.all[3], rating: 4.6, reviewCount: 2100, salesCount: 18000, isInStock: true),
            Product(id: UUID(), name: "快充充电宝", description: "大容量快充", price: 129, originalPrice: 169, imageName: "product_12_bottle", category: Category.all[3], rating: 4.7, reviewCount: 3200, salesCount: 25000, isInStock: true),
        ]),
        CategoryPage(id: UUID(), name: "家居生活", iconName: "icon_home", bannerName: "banner_new", subcategories: ["家纺", "收纳", "厨具", "家装"], products: [
            Product(id: UUID(), name: "不锈钢保温水瓶", description: "持久保温", price: 89, originalPrice: 129, imageName: "product_12_bottle", category: Category.all[4], rating: 4.5, reviewCount: 1600, salesCount: 12000, isInStock: true),
            Product(id: UUID(), name: "全棉四件套", description: "柔软舒适", price: 259, originalPrice: 359, imageName: "product_11_tote", category: Category.all[4], rating: 4.8, reviewCount: 890, salesCount: 4200, isInStock: true),
            Product(id: UUID(), name: "智能LED台灯", description: "护眼设计", price: 99, originalPrice: 149, imageName: "product_01_watch", category: Category.all[4], rating: 4.6, reviewCount: 2100, salesCount: 15000, isInStock: true),
        ]),
        CategoryPage(id: UUID(), name: "运动户外", iconName: "icon_sport", bannerName: "banner_flash", subcategories: ["运动鞋", "健身", "户外", "箱包"], products: [
            Product(id: UUID(), name: "经典帆布硫化鞋", description: "时尚百搭", price: 159, originalPrice: 219, imageName: "product_05_sneakers", category: Category.all[5], rating: 4.7, reviewCount: 2800, salesCount: 20000, isInStock: true),
            Product(id: UUID(), name: "瑜伽垫加厚", description: "防滑耐用", price: 89, originalPrice: 129, imageName: "product_04_serum", category: Category.all[5], rating: 4.5, reviewCount: 1900, salesCount: 16000, isInStock: true),
            Product(id: UUID(), name: "双肩背包旅行", description: "大容量防水", price: 199, originalPrice: 279, imageName: "product_11_tote", category: Category.all[5], rating: 4.8, reviewCount: 1100, salesCount: 7800, isInStock: true),
        ]),
        CategoryPage(id: UUID(), name: "食品生鲜", iconName: "icon_food", bannerName: "banner_summer", subcategories: ["零食", "茶叶", "水果", "粮油"], products: [
            Product(id: UUID(), name: "进口混合坚果", description: "营养健康", price: 89, originalPrice: 119, imageName: "product_12_bottle", category: Category.all[6], rating: 4.6, reviewCount: 2200, salesCount: 18000, isInStock: true),
            Product(id: UUID(), name: "云南古树普洱", description: "正宗云南产", price: 159, originalPrice: 219, imageName: "product_03_mug", category: Category.all[6], rating: 4.9, reviewCount: 780, salesCount: 4500, isInStock: true),
            Product(id: UUID(), name: "纯正蜂蜜500g", description: "天然纯正", price: 69, originalPrice: 99, imageName: "product_04_serum", category: Category.all[6], rating: 4.7, reviewCount: 1300, salesCount: 9500, isInStock: true),
        ]),
        CategoryPage(id: UUID(), name: "潮流配饰", iconName: "icon_beauty", bannerName: "banner_new", subcategories: ["腕表", "眼镜", "包包", "首饰"], products: [
            Product(id: UUID(), name: "简约真皮腕表", description: "时尚简约", price: 299, originalPrice: 399, imageName: "product_01_watch", category: Category.all[7], rating: 4.8, reviewCount: 1800, salesCount: 12000, isInStock: true),
            Product(id: UUID(), name: "复古墨镜", description: "遮阳防晒", price: 159, originalPrice: 219, imageName: "product_05_sneakers", category: Category.all[7], rating: 4.5, reviewCount: 950, salesCount: 6800, isInStock: true),
            Product(id: UUID(), name: "轻奢手提包", description: "品质皮料", price: 399, originalPrice: 559, imageName: "product_11_tote", category: Category.all[7], rating: 4.9, reviewCount: 620, salesCount: 3200, isInStock: true),
        ]),
    ]

    // MARK: - API Methods (async with mock delay)
    private static func mockRequest<T>(_ data: T, delay: UInt64 = 300_000_000) async -> T {
        try? await Task.sleep(nanoseconds: delay)
        return data
    }

    static func getProducts(for category: Category? = nil) async -> [Product] {
        let products = allProducts
        guard let category = category, category.name != "All" else {
            return products
        }
        return await mockRequest(products.filter { $0.category.id == category.id })
    }

    static func searchProducts(query: String) async -> [Product] {
        let products = allProducts
        guard !query.isEmpty else { return await mockRequest(products) }
        let lowercased = query.lowercased()
        return await mockRequest(products.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased)
        })
    }

    static func getProduct(by id: UUID) async -> Product? {
        await mockRequest(allProducts.first { $0.id == id })
    }

    static func getFeaturedProducts() async -> [Product] {
        await mockRequest(Array(allProducts.prefix(4)))
    }

    static func getOnSaleProducts() async -> [Product] {
        await mockRequest(flashSaleProducts)
    }

    static func getBanners() async -> [Banner] {
        await mockRequest(banners)
    }

    static func getCategories() async -> [CategoryPage] {
        await mockRequest(categoryPages)
    }

    static func getCategoryPage(by id: UUID) async -> CategoryPage? {
        await mockRequest(categoryPages.first { $0.id == id })
    }

    static func getProducts(forCategoryId categoryId: UUID) async -> [Product] {
        let page = categoryPages.first { $0.id == categoryId }
        return await mockRequest(page?.products ?? [])
    }
}
