import Foundation

// MARK: - CartItem (购物车里的单个商品)
struct CartItem: Identifiable, Hashable, Codable {
    let id: String  // backend cart item ID (string UUID)
    let product: Product
    let skuId: String?
    let spec: String?
    let unitPrice: Decimal?
    let originalPrice: Decimal?
    let image: String?
    var quantity: Int
    var isSelected: Bool

    enum CodingKeys: String, CodingKey {
        case id, product, quantity, spec, image
        case skuId = "sku_id"
        case unitPrice = "unit_price"
        case originalPrice = "original_price"
        case isSelected = "is_selected"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        product = try container.decode(Product.self, forKey: .product)
        skuId = try container.decodeIfPresent(String.self, forKey: .skuId)
        spec = try container.decodeIfPresent(String.self, forKey: .spec)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        isSelected = try container.decodeIfPresent(Bool.self, forKey: .isSelected) ?? true
        unitPrice = Self.decodeDecimalIfPresent(container, forKey: .unitPrice)
        originalPrice = Self.decodeDecimalIfPresent(container, forKey: .originalPrice)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(product, forKey: .product)
        try container.encodeIfPresent(skuId, forKey: .skuId)
        try container.encodeIfPresent(spec, forKey: .spec)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(isSelected, forKey: .isSelected)
        if let unitPrice { try container.encode("\(unitPrice)", forKey: .unitPrice) }
        if let originalPrice { try container.encode("\(originalPrice)", forKey: .originalPrice) }
    }

    private static func decodeDecimalIfPresent(_ container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Decimal? {
        if let decimal = try? container.decode(Decimal.self, forKey: key) {
            return decimal
        }
        if let string = try? container.decode(String.self, forKey: key) {
            return Decimal(string: string)
        }
        if let double = try? container.decode(Double.self, forKey: key) {
            return Decimal(double)
        }
        return nil
    }

    var totalPrice: Decimal {
        (unitPrice ?? product.price) * Decimal(quantity)
    }

    var displayPrice: Decimal {
        unitPrice ?? product.price
    }

    var imageURL: URL? {
        if let image, let url = URL(string: image) {
            return url
        }
        return product.imageURL
    }

    var formattedTotalPrice: String {
        totalPrice.rmbText
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
    @Published var errorMessage: String? = nil

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var totalPrice: Decimal {
        items.reduce(Decimal.zero) { $0 + $1.totalPrice }
    }

    var formattedTotalPrice: String {
        totalPrice.rmbText
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
            self.errorMessage = nil
        } catch {
            self.errorMessage = userFacingErrorMessage(error, fallback: "购物车加载失败")
        }
        isLoading = false
    }

    func addToCart(_ product: Product, skuId: String? = nil, quantity: Int = 1) async throws {
        try await addItem(product, quantity: quantity, skuId: skuId)
        await loadCart()
    }

    func addItem(_ product: Product, quantity: Int = 1, skuId: String? = nil) async throws {
        struct AddRequest: Encodable { let productId: String; let quantity: Int; let skuId: String? }
        _ = try await APIClient.shared.request(
            endpoint: APIEndpoints.cart,
            method: "POST",
            body: AddRequest(productId: product.id, quantity: quantity, skuId: skuId),
            requiresAuth: true
        ) as CartItem
    }

    func removeFromCart(_ product: Product) {
        guard let cartItem = items.first(where: { $0.product.id == product.id }) else { return }
        Task {
            try? await removeItem(cartItemId: cartItem.id)
            await loadCart()
        }
    }

    func removeItem(cartItemId: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.cartItem(cartItemId),
            method: "DELETE",
            requiresAuth: true
        )
    }

    func updateQuantity(for product: Product, quantity: Int) {
        guard let cartItem = items.first(where: { $0.product.id == product.id }) else { return }
        Task {
            try? await updateQuantityItem(cartItemId: cartItem.id, quantity: quantity)
            await loadCart()
        }
    }

    func updateQuantityItem(cartItemId: String, quantity: Int) async throws {
        struct UpdateRequest: Encodable { let quantity: Int }
        _ = try await APIClient.shared.request(
            endpoint: APIEndpoints.cartItem(cartItemId),
            method: "PUT",
            body: UpdateRequest(quantity: quantity),
            requiresAuth: true
        ) as CartItem
    }

    func incrementItem(_ item: CartItem) {
        Task {
            try? await updateQuantityItem(cartItemId: item.id, quantity: item.quantity + 1)
            await loadCart()
        }
    }

    func decrementItem(_ item: CartItem) {
        Task {
            if item.quantity > 1 {
                try? await updateQuantityItem(cartItemId: item.id, quantity: item.quantity - 1)
            } else {
                try? await removeItem(cartItemId: item.id)
            }
            await loadCart()
        }
    }

    func toggleSelectionItem(_ item: CartItem) {
        Task {
            try? await toggleSelected(cartItemId: item.id)
            await loadCart()
        }
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
        guard let cartItem = items.first(where: { $0.product.id == product.id }) else { return }
        Task {
            try? await toggleSelected(cartItemId: cartItem.id)
            await loadCart()
        }
    }

    func toggleSelected(cartItemId: String) async throws {
        try await APIClient.shared.requestNoData(
            endpoint: APIEndpoints.cartToggle(cartItemId),
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
            endpoint: APIEndpoints.cartClear,
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
