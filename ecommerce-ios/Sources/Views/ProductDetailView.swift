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

                // Floating top buttons
                floatingTopBar
            }
            .navigationBarHidden(true)
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
            SpecSheetView(
                product: product,
                quantity: $quantity,
                isFavorite: $isFavorite,
                onAddToCart: { addToCart() },
                onBuyNow: { buyNow() }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Floating Top Bar
    private var floatingTopBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(Color(.darkGray))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: { /* share */ }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundStyle(Color(.darkGray))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Product Image Section
    private var productImageSection: some View {
        ZStack(alignment: .bottom) {
            // Image swiper - full width, full image display
            GeometryReader { geometry in
                Image(product.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
            }
            .frame(height: UIScreen.main.bounds.width)

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
                value: "黑色经典款/标准版",
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

    // MARK: - Shop Section
    private var shopSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(product.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipped()
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
                Image(product.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
            }
            .frame(height: UIScreen.main.bounds.width)
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
                    ForEach(Product.recommendedProducts) { relatedProduct in
                        RelatedProductCard(product: relatedProduct)
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
        for _ in 0..<quantity {
            cart.addToCart(product)
        }
        showToast()
    }

    private func buyNow() {
        addToCart()
        // Navigate to cart
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
            Image(product.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 140)
                .clipped()

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
    let product: Product
    @Binding var quantity: Int
    @Binding var isFavorite: Bool
    var onAddToCart: () -> Void
    var onBuyNow: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedColor = "黑色经典款"
    @State private var selectedSize = "标准版"
    @State private var showToast = false

    private let accentColor = DesignSystem.Colors.accent
    private let colors = ["黑色", "银色", "金色"]
    private let sizes = ["标准版", "礼盒版"]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Product info
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 90, height: 90)
                            .overlay {
                                Image(product.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.formattedPrice)
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(accentColor)

                            Text("库存 128 件")
                                .font(.caption)
                                .foregroundStyle(.gray)

                            Text("已选：\(selectedColor) / \(selectedSize)")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Color options
                    VStack(alignment: .leading, spacing: 10) {
                        Text("颜色")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)

                        WrapHStack(spacing: 8) {
                            ForEach(colors, id: \.self) { color in
                                SpecOption(
                                    text: color,
                                    isSelected: selectedColor == color,
                                    isDisabled: color == "银色",
                                    onTap: { selectedColor = color }
                                )
                            }
                        }
                    }

                    // Size options
                    VStack(alignment: .leading, spacing: 10) {
                        Text("规格")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)

                        WrapHStack(spacing: 8) {
                            ForEach(sizes, id: \.self) { size in
                                SpecOption(
                                    text: size,
                                    isSelected: selectedSize == size,
                                    onTap: { selectedSize = size }
                                )
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
}

// MARK: - Spec Option
struct SpecOption: View {
    let text: String
    let isSelected: Bool
    var isDisabled: Bool = false
    var onTap: () -> Void

    private let accentColor = DesignSystem.Colors.accent

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? accentColor : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? accentColor.opacity(0.1) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? accentColor : Color.gray.opacity(0.2), lineWidth: 1.5)
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
    ProductDetailView(product: Product.allProducts[0])
        .environmentObject(Cart())
}
