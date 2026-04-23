import Foundation

// MARK: - CartItem (购物车里的单个商品)
struct CartItem: Identifiable, Hashable {
    let id: UUID
    let product: Product
    var quantity: Int
    var isSelected: Bool = true

    var totalPrice: Decimal {
        product.price * Decimal(quantity)
    }

    var formattedTotalPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSDecimalNumber(decimal: totalPrice)) ?? "¥\(totalPrice)"
    }
}

// MARK: - Cart (Global Shopping Cart State)
@MainActor
final class Cart: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var isLoading: Bool = false

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var totalPrice: Decimal {
        items.reduce(Decimal.zero) { $0 + $1.totalPrice }
    }

    var formattedTotalPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSDecimalNumber(decimal: totalPrice)) ?? "¥\(totalPrice)"
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    init() {
        Task {
            await loadCart()
        }
    }

    // MARK: - Persistence Keys
    private static let cartKey = "cart_items"

    // MARK: - Persistence
    private func loadFromStorage() -> [CartItem] {
        guard let data = UserDefaults.standard.data(forKey: Self.cartKey),
              let items = try? JSONDecoder().decode([CodableCartItem].self, from: data) else {
            return []
        }
        return items.map { $0.toCartItem() }
    }

    private func saveToStorage(_ items: [CartItem]) {
        let codable = items.map { CodableCartItem(from: $0) }
        if let data = try? JSONEncoder().encode(codable) {
            UserDefaults.standard.set(data, forKey: Self.cartKey)
        }
    }

    private struct CodableCartItem: Codable {
        let id: UUID
        let productId: UUID
        let productName: String
        let productDescription: String
        let productPrice: Decimal
        let productOriginalPrice: Decimal?
        let productImageName: String
        let productCategoryId: UUID
        let productCategoryName: String
        let productCategoryIconName: String
        let productRating: Double
        let productReviewCount: Int
        let productSalesCount: Int
        let productIsInStock: Bool
        let quantity: Int
        let isSelected: Bool

        init(from item: CartItem) {
            self.id = item.id
            self.productId = item.product.id
            self.productName = item.product.name
            self.productDescription = item.product.description
            self.productPrice = item.product.price
            self.productOriginalPrice = item.product.originalPrice
            self.productImageName = item.product.imageName
            self.productCategoryId = item.product.category.id
            self.productCategoryName = item.product.category.name
            self.productCategoryIconName = item.product.category.iconName
            self.productRating = item.product.rating
            self.productReviewCount = item.product.reviewCount
            self.productSalesCount = item.product.salesCount
            self.productIsInStock = item.product.isInStock
            self.quantity = item.quantity
            self.isSelected = item.isSelected
        }

        func toCartItem() -> CartItem {
            let category = Category(id: productCategoryId, name: productCategoryName, iconName: productCategoryIconName)
            let product = Product(id: productId, name: productName, description: productDescription, price: productPrice, originalPrice: productOriginalPrice, imageName: productImageName, category: category, rating: productRating, reviewCount: productReviewCount, salesCount: productSalesCount, isInStock: productIsInStock)
            return CartItem(id: id, product: product, quantity: quantity, isSelected: isSelected)
        }
    }

    // MARK: - Mock Data
    private static let mockItems: [CartItem] = [
        CartItem(id: UUID(), product: Product(id: UUID(), name: "简约真皮腕表", description: "时尚简约，真皮表带", price: 299, originalPrice: nil, imageName: "product_01_watch", category: Category.all[7], rating: 4.8, reviewCount: 1200, salesCount: 23000, isInStock: true), quantity: 1),
        CartItem(id: UUID(), product: Product(id: UUID(), name: "无线蓝牙耳机", description: "主动降噪，高品质音效", price: 199, originalPrice: nil, imageName: "product_02_earbuds", category: Category.all[3], rating: 4.7, reviewCount: 890, salesCount: 18000, isInStock: true), quantity: 2),
        CartItem(id: UUID(), product: Product(id: UUID(), name: "经典帆布硫化鞋", description: "时尚百搭，舒适透气", price: 159, originalPrice: nil, imageName: "product_05_sneakers", category: Category.all[5], rating: 4.7, reviewCount: 1800, salesCount: 20000, isInStock: true), quantity: 1),
        CartItem(id: UUID(), product: Product(id: UUID(), name: "天然香薰蜡烛 150g", description: "纯天然植物精油", price: 89, originalPrice: nil, imageName: "product_10_candle", category: Category.all[4], rating: 4.8, reviewCount: 1200, salesCount: 12000, isInStock: true), quantity: 3),
    ]

    // MARK: - API Methods
    private func mockRequest<T>(_ data: T, delay: UInt64 = 300_000_000) async -> T {
        try? await Task.sleep(nanoseconds: delay)
        return data
    }

    func loadCart() async {
        isLoading = true
        var stored = loadFromStorage()
        if stored.isEmpty {
            stored = Self.mockItems
            saveToStorage(stored)
        }
        items = stored
        isLoading = false
    }

    func addToCart(_ product: Product) {
        Task {
            _ = await addItem(product)
            await loadCart()
        }
    }

    func addItem(_ product: Product, quantity: Int = 1) async -> Bool {
        var stored = loadFromStorage()
        if let index = stored.firstIndex(where: { $0.product.id == product.id }) {
            stored[index].quantity = min(stored[index].quantity + quantity, 99)
        } else {
            stored.append(CartItem(id: UUID(), product: product, quantity: min(quantity, 99)))
        }
        saveToStorage(stored)
        return await mockRequest(true)
    }

    func removeFromCart(_ product: Product) {
        Task {
            _ = await removeItem(productId: product.id)
            await loadCart()
        }
    }

    func removeItem(productId: UUID) async -> Bool {
        var stored = loadFromStorage()
        stored.removeAll { $0.product.id == productId }
        saveToStorage(stored)
        return await mockRequest(true)
    }

    func updateQuantity(for product: Product, quantity: Int) {
        Task {
            _ = await updateQuantity(productId: product.id, quantity: quantity)
            await loadCart()
        }
    }

    func updateQuantity(productId: UUID, quantity: Int) async -> Bool {
        var stored = loadFromStorage()
        guard let index = stored.firstIndex(where: { $0.product.id == productId }) else {
            return await mockRequest(false)
        }
        if quantity <= 0 {
            stored.remove(at: index)
        } else {
            stored[index].quantity = min(quantity, 99)
        }
        saveToStorage(stored)
        return await mockRequest(true)
    }

    func incrementQuantity(for product: Product) {
        let currentQty = items.first { $0.product.id == product.id }?.quantity ?? 1
        updateQuantity(for: product, quantity: currentQty + 1)
    }

    func decrementQuantity(for product: Product) {
        let currentQty = items.first { $0.product.id == product.id }?.quantity ?? 1
        updateQuantity(for: product, quantity: currentQty - 1)
    }

    func clearCart() {
        Task {
            _ = await clear()
            await loadCart()
        }
    }

    func clear() async -> Bool {
        saveToStorage([])
        return await mockRequest(true)
    }

    func isInCart(_ product: Product) -> Bool {
        items.contains { $0.product.id == product.id }
    }

    func quantity(for product: Product) -> Int {
        items.first { $0.product.id == product.id }?.quantity ?? 0
    }

    func toggleSelection(for product: Product) {
        Task {
            _ = await toggleSelected(productId: product.id)
            await loadCart()
        }
    }

    func toggleSelected(productId: UUID) async -> Bool {
        var stored = loadFromStorage()
        guard let index = stored.firstIndex(where: { $0.product.id == productId }) else {
            return await mockRequest(false)
        }
        stored[index].isSelected.toggle()
        saveToStorage(stored)
        return await mockRequest(true)
    }

    func selectAll(_ selected: Bool) {
        Task {
            _ = await selectAllItems(selected)
            await loadCart()
        }
    }

    func selectAllItems(_ selected: Bool) async -> Bool {
        var stored = loadFromStorage()
        for index in stored.indices {
            stored[index].isSelected = selected
        }
        saveToStorage(stored)
        return await mockRequest(true)
    }

    var selectedItems: [CartItem] {
        items.filter { $0.isSelected }
    }

    var selectedCount: Int {
        selectedItems.reduce(0) { $0 + $1.quantity }
    }

    var selectedTotalPrice: Decimal {
        selectedItems.reduce(Decimal.zero) { $0 + $1.totalPrice }
    }

    var isAllSelected: Bool {
        !items.isEmpty && items.allSatisfy { $0.isSelected }
    }

    var hasSelectedItems: Bool {
        items.contains { $0.isSelected }
    }
}
