import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject private var cart: Cart
    @EnvironmentObject private var appNavigation: AppNavigation
    @EnvironmentObject private var authManager: LoginView
    @Environment(\.dismiss) private var dismiss

    @State private var quantity: Int = 1
    @State private var addedToast: String? = nil
    @State private var selectedImageIndex = 0
    @State private var showingSpecSheet = false
    @State private var isFavorite = false
    @State private var favoriteId: String? = nil
    @State private var productReviews: [ProductReviewItem] = []
    @State private var relatedProducts: [Product] = []
    @State private var productDetail: ProductDetail?
    @State private var selectedSpecs: [String: String] = [:]  // groupId: valueId
    @State private var availableSpecs: [String: Set<String>] = [:]  // groupId: available valueIds
    @State private var selectedSKU: SKU?
    @State private var detailLoadError: String? = nil
    @State private var isAddingToCart = false
    @State private var showShop = false
    @State private var showLogin = false

    private var canStartPurchase: Bool {
        product.isInStock && !isAddingToCart
    }

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
            .background(DesignSystem.Colors.light)
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
            .toast($addedToast, bottomPadding: 100)
            .navigationDestination(isPresented: $showShop) {
                ShopView()
            }
            .sheet(isPresented: $showLogin) {
                LoginFormView()
                    .environmentObject(authManager)
            }
        }
        .sheet(isPresented: $showingSpecSheet) {
            Group {
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
                } else {
                    VStack(spacing: 14) {
                        if detailLoadError == nil {
                            ProgressView()
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(DesignSystem.Colors.accent)
                        }

                        Text(detailLoadError ?? "规格加载中，请稍后")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: { showingSpecSheet = false }) {
                            Text("关闭")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 140, height: 42)
                                .background(DesignSystem.Colors.accent)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(24)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .task {
            await recordBrowseHistory()
            await loadProductDetail()
            await loadRelatedProducts()
            await loadReviews()
            await checkFavoriteStatus()
        }
    }

    private func loadProductDetail() async {
        do {
            detailLoadError = nil
            productDetail = try await Product.getDetail(id: product.id)
            await fetchAvailability()
        } catch {
            detailLoadError = friendlyErrorMessage(error, fallback: "规格加载失败，请稍后重试")
            addedToast = detailLoadError
        }
    }

    private func loadRelatedProducts() async {
        do {
            relatedProducts = try await Product.getRelatedProducts(for: product.id)
        } catch {
            relatedProducts = []
        }
    }

    private func loadReviews() async {
        do {
            productReviews = try await Product.getReviews(id: product.id)
        } catch {
            productReviews = []
        }
    }

    private func checkFavoriteStatus() async {
        do {
            let result = try await FavoriteProduct.checkFavorite(productId: product.id)
            isFavorite = result.isFavorited
            favoriteId = result.favoriteId
        } catch {
            // Not logged in or error — leave isFavorite = false
        }
    }

    private func recordBrowseHistory() async {
        guard APIClient.shared.isAuthenticated else { return }
        try? await HistoryItem.add(productId: product.id)
    }

    private func fetchAvailability() async {
        guard let detail = productDetail else {
            return
        }
        let selectedIds = Array(selectedSpecs.values)

        if selectedIds.isEmpty {
            var allAvailable: [String: Set<String>] = [:]
            for group in detail.specGroups {
                let valueIds = group.values.map { $0.id }
                allAvailable[group.id] = Set(valueIds)
            }
            availableSpecs = allAvailable
            return
        }

        do {
            let responses = try await Product.getSpecAvailable(productId: detail.id, selectedIds: selectedIds)
            var newAvailable: [String: Set<String>] = [:]
            for resp in responses {
                newAvailable[resp.groupId] = Set(resp.availableValues)
            }
            for group in detail.specGroups {
                if newAvailable[group.id] == nil {
                    newAvailable[group.id] = Set(group.values.map { $0.id })
                }
            }
            availableSpecs = newAvailable
        } catch {
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
            GeometryReader { geometry in
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(displayImages.enumerated()), id: \.offset) { index, imagePath in
                        AsyncImage(url: URL(string: imagePath)) { image in
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
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .aspectRatio(1, contentMode: .fit)

            if displayImages.count > 1 {
                HStack(spacing: 6) {
                    ForEach(displayImages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == selectedImageIndex ? .white : .white.opacity(0.45))
                            .frame(width: index == selectedImageIndex ? 8 : 6, height: index == selectedImageIndex ? 8 : 6)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 16)
            }

            Text("\(min(selectedImageIndex + 1, max(displayImages.count, 1)))/\(max(displayImages.count, 1))")
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
                    .foregroundStyle(DesignSystem.Colors.accent)

                if let originalPrice = product.formattedOriginalPrice {
                    Text(originalPrice)
                        .font(.subheadline)
                        .strikethrough()
                        .foregroundStyle(.gray)
                }

                Text("限时特惠")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DesignSystem.Colors.accent.opacity(0.1))
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
        .padding(.horizontal, 16)
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
                valueColor: DesignSystem.Colors.accent,
                showArrow: true
            )
            .onTapGesture {
                addedToast = "服务：极速退款 · 7天无理由 · 运费险"
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
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

    private var displayImages: [String] {
        let images = productDetail?.detail?.images.filter { !$0.isEmpty } ?? []
        if !images.isEmpty { return images }
        return [product.image].filter { !$0.isEmpty }
    }

    private var detailImages: [String] {
        let images = productDetail?.detail?.detailImages.filter { !$0.isEmpty } ?? []
        return images.isEmpty ? displayImages : images
    }

    // MARK: - Shop Section
    private var shopSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay {
                        AsyncImage(url: productDetail?.detail?.shopLogoURL ?? product.imageURL) { image in
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
                    Text(productDetail?.detail?.shopName ?? "潮流优品官方旗舰店")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(DesignSystem.Colors.accent)
                            Text("4.9")
                                .font(.caption)
                        }
                        Text("在售 286 件宝贝")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                Button(action: { showShop = true }) {
                    Text("进店逛逛")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.accent)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(DesignSystem.Colors.accent, lineWidth: 1.5)
                        )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Reviews Section
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("商品评价")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)

                Text(String(format: "%.1f", productDetail?.rating ?? product.rating))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.accent)

                Spacer()

                NavigationLink(destination: ReviewsView(product: product)) {
                    HStack(spacing: 2) {
                        Text("查看全部")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.gray)
                }
            }

            if productReviews.isEmpty {
                Text("暂无评价")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            } else {
                ForEach(productReviews.prefix(2)) { review in
                    ReviewSnippetView(review: review)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
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

            ForEach(Array(detailImages.enumerated()), id: \.offset) { _, imagePath in
                GeometryReader { geometry in
                    AsyncImage(url: URL(string: imagePath)) { image in
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
                Button(action: { Task { await toggleFavorite() } }) {
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
                    Button(action: {
                        appNavigation.selectedTab = .cart
                        dismiss()
                    }) {
                        Image(systemName: "bag")
                            .font(.system(size: 22))
                            .foregroundStyle(.gray)
                    }

                    if cart.totalItems > 0 {
                        Text("\(cart.totalItems)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(DesignSystem.Colors.accent)
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
                Button(action: {
                    guard product.isInStock else {
                        addedToast = "商品暂时无货"
                        return
                    }
                    showingSpecSheet = true
                }) {
                    HStack(spacing: 6) {
                        if isAddingToCart {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.75)
                        }
                        Text("加入购物车")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(canStartPurchase ? Color.black : DesignSystem.Colors.gray2)
                    .clipShape(Capsule())
                }
                .disabled(isAddingToCart)

                Button(action: { buyNow() }) {
                    Text("立即购买")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(canStartPurchase ? DesignSystem.Colors.accent : DesignSystem.Colors.gray2)
                        .clipShape(Capsule())
                }
                .disabled(isAddingToCart)
            }
            .padding(.leading, 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(height: 0.5),
            alignment: .top
        )
    }

    // MARK: - Actions
    private func addToCart(goToCart: Bool = false) {
        guard authManager.isAuthenticated else {
            showingSpecSheet = false
            showLogin = true
            return
        }
        guard product.isInStock else {
            addedToast = "商品暂时无货"
            return
        }
        guard let detail = productDetail else {
            addedToast = detailLoadError ?? "规格加载中，请稍后"
            return
        }
        if !detail.specGroups.isEmpty && selectedSKU == nil {
            showingSpecSheet = true
            return
        }
        if let selectedSKU, selectedSKU.stock <= 0 {
            addedToast = "该规格暂无库存"
            return
        }

        Task { @MainActor in
            guard !isAddingToCart else { return }
            isAddingToCart = true
            defer { isAddingToCart = false }

            do {
                try await cart.addToCart(product, skuId: selectedSKU?.id, quantity: quantity)
                showingSpecSheet = false
                addedToast = quantity > 1 ? "已加入购物车 ×\(quantity)" : "已加入购物车"
                if goToCart {
                    appNavigation.selectedTab = .cart
                    dismiss()
                }
            } catch {
                addedToast = friendlyErrorMessage(error, fallback: "加入购物车失败")
            }
        }
    }

    private func buyNow() {
        guard authManager.isAuthenticated else {
            showingSpecSheet = false
            showLogin = true
            return
        }
        guard product.isInStock else {
            addedToast = "商品暂时无货"
            return
        }
        guard let detail = productDetail else { return }
        if !detail.specGroups.isEmpty && selectedSKU == nil {
            showingSpecSheet = true
            return
        }
        addToCart(goToCart: true)
    }

    private func friendlyErrorMessage(_ error: Error, fallback: String) -> String {
        if let message = (error as? LocalizedError)?.errorDescription, !message.isEmpty {
            return message
        }
        return fallback
    }

    private func toggleFavorite() async {
        guard authManager.isAuthenticated else {
            showLogin = true
            return
        }
        if isFavorite, let id = favoriteId {
            do {
                try await FavoriteProduct.removeFavorite(id: id)
                isFavorite = false
                favoriteId = nil
                addedToast = "已取消收藏"
            } catch {
                addedToast = userFacingErrorMessage(error, fallback: "取消收藏失败")
            }
        } else {
            do {
                let newId = try await FavoriteProduct.addFavorite(productId: product.id)
                isFavorite = true
                favoriteId = newId
                addedToast = "已收藏"
            } catch {
                addedToast = userFacingErrorMessage(error, fallback: "收藏失败")
            }
        }
    }
}

private struct ReviewSnippetView: View {
    let review: ProductReviewItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.accent, Color(red: 1.0, green: 0.6, blue: 0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(review.userName.prefix(1)))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }

                Text(review.userName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= review.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(index <= review.rating ? DesignSystem.Colors.accent : Color(.systemGray4))
                    }
                }
            }

            Text(review.content)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineSpacing(4)

            if !review.spec.isEmpty {
                Text("购买规格：\(review.spec)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Promo Tag
struct PromoTag: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(DesignSystem.Colors.accent)

            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.accent)
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
                    .foregroundStyle(DesignSystem.Colors.accent)
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
                                .foregroundStyle(DesignSystem.Colors.accent)

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
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.primary)

                            WrapHStack(horizontalSpacing: 10, verticalSpacing: 10) {
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
                }) {
                    Text("加入购物车")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canSubmit ? Color.black : DesignSystem.Colors.gray2)
                        .clipShape(Capsule())
                }
                .disabled(!canSubmit)

                Button(action: {
                    onBuyNow()
                }) {
                    Text("立即购买")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canSubmit ? DesignSystem.Colors.accent : DesignSystem.Colors.gray2)
                        .clipShape(Capsule())
                }
                .disabled(!canSubmit)
            }
            .padding(14)
            .padding(.bottom, 14)
        }
    }

    private var canSubmit: Bool {
        if productDetail.specGroups.isEmpty {
            return productDetail.isInStock
        }
        guard selectedSpecs.count == productDetail.specGroups.count,
              let selectedSKU else {
            return false
        }
        return selectedSKU.stock > 0
    }

    private var formattedPrice: String {
        if let sku = selectedSKU {
            return sku.price.rmbText
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
            return available.contains(valueId)
        }
        return true
    }

    private func toggleSpec(groupId: String, valueId: String) {
        // Toggle selection - if already selected, deselect (same as H5)
        if selectedSpecs[groupId] == valueId {
            selectedSpecs.removeValue(forKey: groupId)
        } else {
            selectedSpecs[groupId] = valueId
        }
        updateSelectedSKU()
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
                .foregroundStyle(isSelected ? DesignSystem.Colors.accent : normalText)
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .frame(minWidth: 56, minHeight: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? selectedBg : normalBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? DesignSystem.Colors.accent : normalBorder, lineWidth: 1.5)
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
    }
}

// MARK: - Wrap HStack for left-aligned flow layout
struct WrapHStack<Content: View>: View {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.horizontalSpacing = spacing
        self.verticalSpacing = spacing
        self.content = content
    }

    init(horizontalSpacing: CGFloat, verticalSpacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }

    var body: some View {
        LeftAlignedFlowLayout(horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Left Aligned Flow Layout
struct LeftAlignedFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? subviews.reduce(0) { partial, subview in
            partial + subview.sizeThatFits(.unspecified).width + horizontalSpacing
        }
        let rows = arrangedRows(maxWidth: maxWidth, subviews: subviews)
        return CGSize(width: proposal.width ?? rows.width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + verticalSpacing
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }

    private func arrangedRows(maxWidth: CGFloat, subviews: Subviews) -> (width: CGFloat, height: CGFloat) {
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let nextWidth = currentWidth == 0 ? size.width : currentWidth + horizontalSpacing + size.width

            if currentWidth > 0 && nextWidth > maxWidth {
                widestRow = max(widestRow, currentWidth)
                totalHeight += currentHeight + verticalSpacing
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentWidth = nextWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        widestRow = max(widestRow, currentWidth)
        totalHeight += currentHeight
        return (widestRow, totalHeight)
    }
}

#Preview {
    Text("ProductDetailView Preview")
}
