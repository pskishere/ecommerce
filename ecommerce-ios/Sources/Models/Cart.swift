import Foundation

// MARK: - CartItem (购物车里的单个商品)
struct CartItem: Identifiable, Hashable, Codable {
    let id: String  // backend cart item ID (string UUID)
    let product: Product
    var quantity: Int
    var isSelected: Bool

    enum CodingKeys: String, CodingKey {
        case id, product, quantity
        case isSelected = "is_selected"
    }

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

// MARK: - Cart Response from Backend
struct CartResponse: Codable {
    let items: [CartItem]
    let total: Double
}

// MARK: - Cart (Global Shopping Cart State)
@MainActor
final class Cart: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var isLoading: Bool = false
    @Published var total: Double = 0

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

    init() { }

    // MARK: - API Methods
    func loadCart() async {
        isLoading = true
        do {
            let resp: CartResponse = try await APIClient.shared.request(
                endpoint: APIEndpoints.cart,
                requiresAuth: true
            )
            self.items = resp.items
            self.total = resp.total
        } catch {
            print("Failed to load cart: \(error)")
        }
        isLoading = false
    }

    func addToCart(_ product: Product) {
        Task {
            try? await addItem(product)
            await loadCart()
        }
    }

    func addItem(_ product: Product, quantity: Int = 1) async throws {
        struct AddRequest: Encodable { let productId: String; let quantity: Int }
        _ = try await APIClient.shared.request(
            endpoint: APIEndpoints.cart,
            method: "POST",
            body: AddRequest(productId: product.id, quantity: quantity),
            requiresAuth: true
        ) as EmptyResponse
    }

    func removeFromCart(_ product: Product) {
        Task {
            try? await removeItem(productId: product.id)
            await loadCart()
        }
    }

    func removeItem(productId: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.cartItem(productId),
            method: "DELETE",
            requiresAuth: true
        )
    }

    func updateQuantity(for product: Product, quantity: Int) {
        Task {
            try? await updateQuantityItem(productId: product.id, quantity: quantity)
            await loadCart()
        }
    }

    func updateQuantityItem(productId: String, quantity: Int) async throws {
        struct UpdateRequest: Encodable { let quantity: Int }
        _ = try await APIClient.shared.request(
            endpoint: APIEndpoints.cartItem(productId),
            method: "PUT",
            body: UpdateRequest(quantity: quantity),
            requiresAuth: true
        ) as EmptyResponse
    }

    func incrementQuantity(for product: Product) {
        let currentQty = items.first { $0.product.id == product.id }?.quantity ?? 1
        updateQuantity(for: product, quantity: currentQty + 1)
    }

    func decrementQuantity(for product: Product) {
        let currentQty = items.first { $0.product.id == product.id }?.quantity ?? 1
        if currentQty > 1 {
            updateQuantity(for: product, quantity: currentQty - 1)
        } else {
            removeFromCart(product)
        }
    }

    func toggleSelection(for product: Product) {
        Task {
            try? await toggleSelected(productId: product.id)
            await loadCart()
        }
    }

    func toggleSelected(productId: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.cartToggle(productId),
            method: "PATCH",
            requiresAuth: true
        )
    }

    func selectAll(_ selected: Bool) {
        Task {
            try? await selectAllItems(selected)
            await loadCart()
        }
    }

    func selectAllItems(_ selected: Bool) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: "\(APIEndpoints.cartSelectAll)?selected=\(selected)",
            method: "PUT",
            requiresAuth: true
        )
    }

    func clearCart() {
        Task {
            try? await clear()
            await loadCart()
        }
    }

    func clear() async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.cart,
            method: "DELETE",
            requiresAuth: true
        )
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

// MARK: - Empty Response
struct EmptyResponse: Codable {}
