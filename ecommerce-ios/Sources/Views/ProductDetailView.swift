import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject private var cart: Cart
    @Environment(\.dismiss) private var dismiss

    @State private var quantity: Int = 1
    @State private var showingAddedToast = false
    @State private var selectedImageIndex = 0
    @State private var showingSpecSheet = false
    @State private var isFavorite = false
    @State private var relatedProducts: [Product] = []
    @State private var productDetail: ProductDetail?
    @State private var selectedSpecs: [String: String] = [:]  // groupId: valueId
    @State private var availableSpecs: [String: Set<String>] = [:]  // groupId: available valueIds
    @State private var selectedSKU: SKU?

    private let accentColor = DesignSystem.Colors.accent

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        productImageSection
                        productInfoCard
                        specSection
                        shopSection
                        reviewsSection
                        detailContentSection
                        relatedProductsSection
                        Spacer(minLength: 100)
                    }
                    .frame(width: geometry.size.width)
                }
                .scrollContentBackground(.hidden)
                .ignoresSafeArea(edges: .top)

            }
            .navigationBarBackButtonHidden(false)
            .hideTabBar()
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
            .overlay {
                if showingAddedToast {
                    toastView
                }
            }
        }
        .sheet(isPresented: $showingSpecSheet) {
            if let detail = productDetail {
                SpecSheetView(
                    productDetail: detail,
                    selectedSpecs: $selectedSpecs,
                    selectedSKU: $selectedSKU,
                    availableSpecs: $availableSpecs,
                    quantity: $quantity,
                    isFavorite: $isFavorite,
                    onSpecsChanged: { Task { await fetchAvailability() } },
                    onAddToCart: { addToCart() },
                    onBuyNow: { buyNow() }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await loadProductDetail()
            await loadRelatedProducts()
        }
    }

    private func loadProductDetail() async {
        do {
            productDetail = try await Product.getDetail(id: product.id)
            await fetchAvailability()
        } catch {
            print("Failed to load product detail: \(error)")
        }
    }

    private func loadRelatedProducts() async {
        do {
            relatedProducts = try await Product.getRelatedProducts(for: product.id)
        } catch {
            print("Failed to load related products: \(error)")
        }
    }

    private func fetchAvailability() async {
        guard let detail = productDetail else {
            print("[DEBUG] fetchAvailability early return - productDetail is nil")
            return
        }
        let selectedIds = Array(selectedSpecs.values)
        print("[DEBUG] fetchAvailability called, detail.id: \(detail.id), selectedIds: \(selectedIds), specGroups count: \(detail.specGroups.count)")

        if selectedIds.isEmpty {
            var allAvailable: [String: Set<String>] = [:]
            for group in detail.specGroups {
                let valueIds = group.values.map { $0.id }
                print("[DEBUG] Group \(group.id) (\(group.name)): \(valueIds)")
                allAvailable[group.id] = Set(valueIds)
            }
            availableSpecs = allAvailable
            print("[DEBUG] No selection - all available: \(allAvailable)")
            return
        }

        do {
            let responses = try await Product.getSpecAvailable(productId: detail.id, selectedIds: selectedIds)
            print("[DEBUG] API returned \(responses.count) groups")
            var newAvailable: [String: Set<String>] = [:]
            for resp in responses {
                newAvailable[resp.groupId] = Set(resp.availableValues)
                print("[DEBUG] Group \(resp.groupId): available \(resp.availableValues)")
            }
            for group in detail.specGroups {
                if newAvailable[group.id] == nil {
                    newAvailable[group.id] = Set(group.values.map { $0.id })
                }
            }
            availableSpecs = newAvailable
            print("[DEBUG] Updated availableSpecs: \(newAvailable)")
        } catch {
            print("[DEBUG] fetchAvailability error: \(error)")
            var allAvailable: [String: Set<String>] = [:]
            for group in detail.specGroups {
                allAvailable[group.id] = Set(group.values.map { $0.id })
            }
            availableSpecs = allAvailable
        }
    }

    // MARK: - Product Image Section
    private var productImageSection: some View {
        ZStack(alignment: .bottom) {
            // Image swiper - full width, full image display
            GeometryReader { geometry in
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                }
            }
            .aspectRatio(1, contentMode: .fit)

            // Page indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.bottom, 16)

            // Image counter
            Text("1/3")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
                .padding(.bottom, 16)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea()
    }

    // MARK: - Product Info Card
    private var productInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Price row
            HStack(alignment: .bottom, spacing: 10) {
                Text(product.formattedPrice)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(accentColor)

                if let originalPrice = product.formattedOriginalPrice {
                    Text(originalPrice)
                        .font(.subheadline)
                        .strikethrough()
                        .foregroundStyle(.gray)
                }

                Text("限时特惠")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.leading, 4)
            }

            // Product title
            Text(product.name)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)
                .lineSpacing(4)

            // Product description
            Text(product.description)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .lineSpacing(4)

            // Promo tags
            HStack(spacing: 12) {
                PromoTag(icon: "checkmark.circle.fill", text: "极速退款")
                PromoTag(icon: "checkmark.circle.fill", text: "7天无理由")
                PromoTag(icon: "checkmark.circle.fill", text: "运费险")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 4)
        .offset(y: -20)
        .padding(.horizontal, 8)
    }

    // MARK: - Spec Section
    private var specSection: some View {
        VStack(spacing: 0) {
            SpecRow(
                icon: "circle.grid.2x2",
                label: "选择",
                value: selectedSpecsText,
                showArrow: true
            )
            .onTapGesture {
                showingSpecSheet = true
            }

            Divider()
                .padding(.leading, 40)

            SpecRow(
                icon: "shield.fill",
                label: "服务",
                value: "极速退款 · 7天无理由 · 运费险",
                valueColor: accentColor,
                showArrow: true
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 8)
    }

    private var selectedSpecsText: String {
        guard let detail = productDetail else { return "请选择规格" }
        var parts: [String] = []
        for group in detail.specGroups {
            if let valueId = selectedSpecs[group.id],
               let specValue = group.values.first(where: { $0.id == valueId }) {
                parts.append(specValue.value)
            }
        }
        return parts.isEmpty ? "请选择规格" : parts.joined(separator: " / ")
    }

    // MARK: - Shop Section
    private var shopSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay {
                        AsyncImage(url: product.imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 52, height: 52)
                                .clipped()
                        } placeholder: {
                            Color.clear
                        }
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("潮流优品官方旗舰店")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(accentColor)
                            Text("4.9")
                                .font(.caption)
                        }
                        Text("在售 286 件宝贝")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                Button(action: {}) {
                    Text("进店逛逛")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(accentColor, lineWidth: 1.5)
                        )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 4)
        .padding(.top, 12)
    }

    // MARK: - Reviews Section
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("商品评价")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)

                Text("4.9")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor)

                Spacer()

                Button(action: {}) {
                    HStack(spacing: 2) {
                        Text("查看全部")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.gray)
                }
            }

            // Review item
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, Color(red: 1.0, green: 0.6, blue: 0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text("林")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    Text("林小琳")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(accentColor)
                        }
                    }
                }

                Text("手表收到啦！做工非常精致，皮质表带很软很舒服，戴上很有气质。走时很准，防水效果也不错，推荐购买！")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)

                Text("购买规格：黑色经典款 / 标准版")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 4)
        .padding(.top, 12)
    }

    // MARK: - Detail Content Section
    private var detailContentSection: some View {
        VStack(spacing: 0) {
            Text("商品详情")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

            // Detail images - fill width
            GeometryReader { geometry in
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Related Products Section
    private var relatedProductsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("猜你喜欢")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(relatedProducts) { relatedProduct in
                        NavigationLink(destination: ProductDetailView(product: relatedProduct)) {
                            RelatedProductCard(product: relatedProduct)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack(spacing: 10) {
            // Icon buttons
            VStack(spacing: 2) {
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundStyle(isFavorite ? .red : .gray)
                }

                Text("收藏")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
            }
            .frame(width: 48)

            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bag")
                            .font(.system(size: 22))
                            .foregroundStyle(.gray)
                    }

                    if cart.totalItems > 0 {
                        Text("\(cart.totalItems)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(accentColor)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }

                Text("购物车")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
            }
            .frame(width: 48)

            // Action buttons
            HStack(spacing: 10) {
                Button(action: { showingSpecSheet = true }) {
                    Text("加入购物车")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.black)
                        .clipShape(Capsule())
                }

                Button(action: { buyNow() }) {
                    Text("立即购买")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.leading, 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(
            Divider(),
            alignment: .top
        )
    }

    // MARK: - Toast
    private var toastView: some View {
        VStack {
            Spacer()
            Text("已加入购物车")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                .padding(.bottom, 100)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Actions
    private func addToCart() {
        guard let detail = productDetail else { return }
        if !detail.specGroups.isEmpty && selectedSKU == nil {
            showingSpecSheet = true
            return
        }
        var productToAdd = product
        if let sku = selectedSKU {
            productToAdd = Product(
                id: product.id,
                name: product.name,
                description: product.description,
                price: sku.price,
                originalPrice: sku.originalPrice,
                image: sku.image ?? product.image,
                subcategoryRef: product.subcategoryRef,
                rating: product.rating,
                reviewCount: product.reviewCount,
                salesCount: product.salesCount,
                isInStock: product.isInStock,
                tag: product.tag
            )
        }
        for _ in 0..<quantity {
            cart.addToCart(productToAdd)
        }
        showToast()
    }

    private func buyNow() {
        guard let detail = productDetail else { return }
        if !detail.specGroups.isEmpty && selectedSKU == nil {
            showingSpecSheet = true
            return
        }
        addToCart()
    }

    private func showToast() {
        withAnimation(.spring(duration: 0.35)) {
            showingAddedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingAddedToast = false
            }
        }
    }
}

// MARK: - Promo Tag
struct PromoTag: View {
    let icon: String
    let text: String
    private let accentColor = DesignSystem.Colors.accent

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(accentColor)

            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accentColor)
        }
    }
}

// MARK: - Spec Row
struct SpecRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary
    var showArrow: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.gray)
                .frame(minHeight: 22)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .frame(minHeight: 22)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
                .frame(minHeight: 22)

            if showArrow {
                Text(">")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .frame(minHeight: 22)
            }
        }
        .padding(16)
    }
}

// MARK: - Related Product Card
struct RelatedProductCard: View {
    let product: Product
    private let accentColor = DesignSystem.Colors.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 140, height: 140)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .top)

                Text(product.formattedPrice)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(accentColor)
            }
            .padding(10)
        }
        .frame(width: 140)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Spec Sheet View
struct SpecSheetView: View {
    let productDetail: ProductDetail
    @Binding var selectedSpecs: [String: String]
    @Binding var selectedSKU: SKU?
    @Binding var availableSpecs: [String: Set<String>]
    @Binding var quantity: Int
    @Binding var isFavorite: Bool
    var onSpecsChanged: () -> Void
    var onAddToCart: () -> Void
    var onBuyNow: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let accentColor = DesignSystem.Colors.accent

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Product info
                    HStack(spacing: 14) {
                        AsyncImage(url: selectedImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        }
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedPrice)
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(accentColor)

                            Text(stockText)
                                .font(.caption)
                                .foregroundStyle(.gray)

                            Text("已选：\(selectedSpecsText)")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Spec groups
                    ForEach(productDetail.specGroups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.primary)

                            WrapHStack(spacing: 2) {
                                ForEach(group.values) { specValue in
                                    SpecOption(
                                        text: specValue.value,
                                        isSelected: selectedSpecs[group.id] == specValue.id,
                                        isDisabled: !isSpecAvailable(groupId: group.id, valueId: specValue.id),
                                        onTap: {
                                            toggleSpec(groupId: group.id, valueId: specValue.id)
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // Quantity
                    HStack {
                        Text("数量")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)

                        Spacer()

                        HStack(spacing: 0) {
                            Button(action: { if quantity > 1 { quantity -= 1 } }) {
                                Text("−")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                    .frame(width: 40, height: 40)
                            }

                            Text("\(quantity)")
                                .font(.system(size: 15, weight: .bold))
                                .frame(width: 44)

                            Button(action: { if quantity < 99 { quantity += 1 } }) {
                                Text("+")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                    .frame(width: 40, height: 40)
                            }
                        }
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
                        )
                    }
                    .padding(.top, 10)
                }
                .padding(20)
            }

            // Bottom buttons
            HStack(spacing: 10) {
                Button(action: {
                    onAddToCart()
                    dismiss()
                }) {
                    Text("加入购物车")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .clipShape(Capsule())
                }

                Button(action: {
                    onBuyNow()
                    dismiss()
                }) {
                    Text("立即购买")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .padding(.bottom, 14)
        }
    }

    private var formattedPrice: String {
        if let sku = selectedSKU {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "CNY"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: NSDecimalNumber(decimal: sku.price)) ?? "¥\(sku.price)"
        }
        return productDetail.formattedPrice
    }

    private var stockText: String {
        if let sku = selectedSKU {
            return sku.stock > 0 ? "库存 \(sku.stock) 件" : "暂无库存"
        }
        return "请选择规格"
    }

    private var selectedSpecsText: String {
        var parts: [String] = []
        for group in productDetail.specGroups {
            if let valueId = selectedSpecs[group.id],
               let specValue = group.values.first(where: { $0.id == valueId }) {
                parts.append(specValue.value)
            }
        }
        return parts.isEmpty ? "" : parts.joined(separator: " / ")
    }

    private var selectedImageURL: URL? {
        if let sku = selectedSKU, let image = sku.image {
            return URL(string: image)
        }
        return productDetail.imageURL
    }

    private func isSpecAvailable(groupId: String, valueId: String) -> Bool {
        if let available = availableSpecs[groupId] {
            let isAvail = available.contains(valueId)
            print("[DEBUG] isSpecAvailable(\(groupId), \(valueId)) = \(isAvail), available: \(available)")
            return isAvail
        }
        print("[DEBUG] isSpecAvailable(\(groupId), \(valueId)) = true (no entry in availableSpecs), availableSpecs: \(availableSpecs)")
        return true
    }

    private func toggleSpec(groupId: String, valueId: String) {
        print("[DEBUG] toggleSpec called with (\(groupId), \(valueId))")
        // Toggle selection - if already selected, deselect (same as H5)
        if selectedSpecs[groupId] == valueId {
            selectedSpecs.removeValue(forKey: groupId)
        } else {
            selectedSpecs[groupId] = valueId
        }
        print("[DEBUG] toggleSpec selectedSpecs now: \(selectedSpecs)")
        updateSelectedSKU()
        print("[DEBUG] toggleSpec calling onSpecsChanged")
        onSpecsChanged()
    }

    private func updateSelectedSKU() {
        let selectedIds = Array(selectedSpecs.values)
        selectedSKU = productDetail.skus.first { sku in
            if sku.specValueIds.count != selectedIds.count { return false }
            return selectedIds.allSatisfy { sku.specValueIds.contains($0) }
        }
    }
}

// MARK: - Spec Option
struct SpecOption: View {
    let text: String
    let isSelected: Bool
    var isDisabled: Bool = false
    var onTap: () -> Void

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)  // #FF6B4A

    private var normalBg: Color { Color(red: 0.97, green: 0.97, blue: 0.97) }  // #F8F8F8
    private var normalBorder: Color { Color(red: 0.90, green: 0.90, blue: 0.90) }  // #E5E5E5
    private var normalText: Color { Color(red: 0.40, green: 0.40, blue: 0.40) }  // #666666
    private var selectedBg: Color { Color(red: 1.0, green: 0.94, blue: 0.93) }  // #FFF0ED

    var body: some View {
        Button(action: {
            if !isDisabled {
                onTap()
            }
        }) {
            Text(text)
                .font(.system(size: 13))
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? accentColor : normalText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? selectedBg : normalBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? accentColor : normalBorder, lineWidth: 1.5)
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
    }
}

// MARK: - Wrap HStack for left-aligned flow layout
struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            FlowLayoutView(spacing: spacing) {
                content()
            }
        }
    }
}

// MARK: - Flow Layout using LazyVGrid
struct FlowLayoutView<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 200), spacing: spacing)], spacing: spacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    Text("ProductDetailView Preview")
}
