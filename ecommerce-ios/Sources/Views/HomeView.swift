import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appNavigation: AppNavigation
    @State private var banners: [Banner] = []
    @State private var flashSaleProducts: [Product] = []
    @State private var hotRankingProducts: [Product] = []
    @State private var recommendedProducts: [Product] = []
    @State private var newArrivalProducts: [Product] = []
    @State private var promotions: [HomePromotion] = []
    @State private var selectedProduct: Product?
    @State private var showCoupons = false
    @State private var isLoading = true
    @State private var loadError: String? = nil
    @State private var toast: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                if isLoading {
                    skeletonContent
                } else if shouldShowErrorState {
                    AppEmptyState(
                        systemImage: "wifi.exclamationmark",
                        title: "首页加载失败",
                        message: loadError ?? "请检查网络后重试",
                        actionTitle: "重试",
                        action: {
                            Task { await loadData() }
                        }
                    )
                    .padding(.top, 120)
                } else {
                    if !banners.isEmpty {
                        heroBanner
                    }
                    categoryGrid
                    if !promotions.isEmpty {
                        promotionSection
                    }
                    if !flashSaleProducts.isEmpty {
                        flashSaleSection
                    }
                    if !newArrivalProducts.isEmpty {
                        newArrivalSection
                    }
                    if !hotRankingProducts.isEmpty {
                        hotRankingsSection
                    }
                    if !recommendedProducts.isEmpty {
                        recommendSection
                    }
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .navigationTitle("潮流好物")
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product)
        }
        .navigationDestination(isPresented: $showCoupons) {
            CouponView()
        }
        .toast($toast, bottomPadding: 96)
        .task {
            await loadData()
        }
    }

    private var shouldShowErrorState: Bool {
        loadError != nil &&
        banners.isEmpty &&
        flashSaleProducts.isEmpty &&
        hotRankingProducts.isEmpty &&
        recommendedProducts.isEmpty &&
        newArrivalProducts.isEmpty &&
        promotions.isEmpty
    }

    // MARK: - Skeleton Loading Content
    private var skeletonContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            SkeletonBanner()
            SkeletonCategoryGrid()
            SkeletonPromotionStrip()
            SkeletonFlashSale()
            SkeletonNewArrival()
            SkeletonHotRanking()
            SkeletonRecommend()
        }
    }

    // MARK: - Hero Banner
    private var heroBanner: some View {
        HeroBanner(banners: banners)
    }

    // MARK: - Category Grid
    private var categoryGrid: some View {
        CategoryGridView()
    }

    // MARK: - Promotion Section
    private var promotionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "ticket.fill")
                        .foregroundStyle(DesignSystem.Colors.accent)
                    Text("活动会场")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Spacer()

                Button(action: { showCoupons = true }) {
                    HStack(spacing: 4) {
                        Text("领券")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(promotions) { promotion in
                        Button(action: { openPromotion(promotion) }) {
                            PromotionCard(promotion: promotion)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    // MARK: - Flash Sale Section
    private var flashSaleSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(DesignSystem.Colors.accent)
                    Text("限时秒杀")
                        .font(.headline)
                        .fontWeight(.bold)

                    FlashCountdown()
                }

                Spacer()

                Button(action: { appNavigation.selectedTab = .category }) {
                    HStack(spacing: 4) {
                        Text("更多")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(flashSaleProducts) { product in
                        productTapArea(product) {
                            FlashSaleCard(product: product)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    // MARK: - Hot Rankings Section
    private var hotRankingsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.29))
                    Text("热销榜单")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Spacer()

                Button(action: { appNavigation.selectedTab = .category }) {
                    HStack(spacing: 4) {
                        Text("查看全部")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.29))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)

            // Bento grid: 1 large card top, 3 small cards bottom
            VStack(spacing: DesignSystem.Spacing.sm) {
                if let firstProduct = hotRankingProducts.first {
                    productTapArea(firstProduct) {
                        HotRankingCard(product: firstProduct, rank: 1, isLarge: true)
                    }

                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(Array(hotRankingProducts.dropFirst().prefix(3).enumerated()), id: \.element.id) { offset, product in
                            productTapArea(product) {
                                HotRankingCard(product: product, rank: offset + 2, isLarge: false)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }

    // MARK: - New Arrival Section
    private var newArrivalSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color(red: 0.18, green: 0.52, blue: 0.43))
                    Text("新品首发")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Spacer()

                Button(action: { appNavigation.selectedTab = .category }) {
                    HStack(spacing: 4) {
                        Text("去发现")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(red: 0.18, green: 0.52, blue: 0.43))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(newArrivalProducts.prefix(8)) { product in
                        productTapArea(product) {
                            NewArrivalCard(product: product)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    // MARK: - Recommend Section
    private var recommendSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("为你推荐")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                HStack(spacing: DesignSystem.Spacing.md) {
                    RecommendTab(title: "新品", isSelected: true)
                    RecommendTab(title: "热门", isSelected: false)
                    RecommendTab(title: "畅销", isSelected: false)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.md)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
            ], spacing: DesignSystem.Spacing.sm) {
                ForEach(recommendedProducts) { product in
                    RecommendCard(product: product) {
                        selectedProduct = product
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }

    // MARK: - Data Loading
    private func loadData() async {
        isLoading = true
        loadError = nil
        do {
            async let bannersTask = Product.getBanners()
            async let flashTask = Product.getFlashSaleProducts()
            async let hotTask = Product.getHotRankingProducts()
            async let recommendTask = Product.getRecommendProducts()
            async let newArrivalTask = Product.getNewArrivalProducts()
            async let promotionTask = Product.getPromotions()

            banners = try await bannersTask
            flashSaleProducts = try await flashTask
            hotRankingProducts = try await hotTask
            recommendedProducts = try await recommendTask
            newArrivalProducts = try await newArrivalTask
            promotions = try await promotionTask
        } catch {
            let message = userFacingErrorMessage(error, fallback: "首页数据加载失败")
            loadError = message
            toast = message
        }
        isLoading = false
    }

    private func productTapArea<Content: View>(
        _ product: Product,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .contentShape(Rectangle())
            .onTapGesture {
                selectedProduct = product
            }
    }

    private func openPromotion(_ promotion: HomePromotion) {
        let link = promotion.link.lowercased()
        if link.contains("coupon") {
            showCoupons = true
        } else if link.contains("category") {
            appNavigation.selectedTab = .category
        } else {
            showCoupons = true
        }
    }
}

// MARK: - Recommend Tab
struct RecommendTab: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(isSelected ? .bold : .medium)
            .foregroundStyle(isSelected ? Color(red: 1.0, green: 0.42, blue: 0.29) : .secondary)
            .padding(.bottom, 4)
            .overlay(
                Rectangle()
                    .fill(isSelected ? Color(red: 1.0, green: 0.42, blue: 0.29) : Color.clear)
                    .frame(height: 2),
                alignment: .bottom
            )
    }
}

// MARK: - Featured Card
struct FeaturedCard: View {
    let product: Product
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            infoSection
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.06),
            radius: 12,
            x: 0,
            y: 4
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(DesignSystem.Animation.snappy, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.accent.opacity(0.08),
                                DesignSystem.Colors.accent.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 200, height: 130)

            if let discount = product.discount {
                Text("-\(discount)%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.accent)
                    )
                    .padding(DesignSystem.Spacing.sm)
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: DesignSystem.Radius.lg,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: DesignSystem.Radius.lg
                )
            )
        )
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.label))
                .lineLimit(1)

            HStack {
                Text(product.formattedPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.accent)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text(String(format: "%.1f", product.rating))
                        .font(.caption)
                }
                .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.0))
            }
        }
        .padding(DesignSystem.Spacing.sm)
    }
}

// MARK: - Promotion Card
struct PromotionCard: View {
    let promotion: HomePromotion

    var body: some View {
        ZStack(alignment: .leading) {
            AsyncImage(url: promotion.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.accent.opacity(0.18),
                        Color(red: 0.18, green: 0.52, blue: 0.43).opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .frame(width: 260, height: 92)
            .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.52),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.02)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            VStack(alignment: .leading, spacing: 7) {
                Text(promotion.title.isEmpty ? "优惠活动" : promotion.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(promotion.subtitle.isEmpty ? "限时福利，立即领取" : promotion.subtitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                Text("去领取")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.accent)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .frame(width: 260, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - New Arrival Card
struct NewArrivalCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 138, height: 150)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.08))
                        .frame(width: 138, height: 150)
                }

                Text("NEW")
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.18, green: 0.52, blue: 0.43))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(8)
            }
            .frame(width: 138, height: 150)
            .background(Color(.secondarySystemBackground))

            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(product.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.accent)

                    Spacer(minLength: 4)

                    Text(product.formattedSalesCount)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .frame(width: 138, height: 76, alignment: .topLeading)
        }
        .frame(width: 138)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
        .environmentObject(Cart())
        .environmentObject(AppNavigation())
        .environmentObject(LoginView.shared)
}

// MARK: - Hero Banner
struct HeroBanner: View {
    let banners: [Banner]
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            TabView(selection: $currentIndex) {
                ForEach(Array(banners.enumerated()), id: \.element.id) { index, banner in
                    BannerSlide(banner: banner)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 180)

            HStack(spacing: 6) {
                ForEach(0..<banners.count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? DesignSystem.Colors.accent : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

struct BannerSlide: View {
    @EnvironmentObject private var appNavigation: AppNavigation
    let banner: Banner

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: banner.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: banner.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: geometry.size.height * 0.6)
                .frame(maxHeight: .infinity, alignment: .bottom)

                VStack(alignment: .leading, spacing: 8) {
                    Text(banner.tag)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())

                    Text(banner.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .lineSpacing(4)

                    Button(action: { appNavigation.selectedTab = .category }) {
                        Text(banner.actionTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(banner.gradientColors[0])
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
    }
}

// MARK: - Flash Countdown
struct FlashCountdown: View {
    @State private var timeRemaining = 2 * 3600 + 41 * 60 + 33

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(formatTime().enumerated()), id: \.offset) { index, digit in
                Text(digit)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(DesignSystem.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                if index < 2 {
                    Text(":")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
        }
    }

    private func formatTime() -> [String] {
        let hours = timeRemaining / 3600
        let minutes = (timeRemaining % 3600) / 60
        let seconds = timeRemaining % 60
        return [
            String(format: "%02d", hours),
            String(format: "%02d", minutes),
            String(format: "%02d", seconds)
        ]
    }
}

// MARK: - Flash Sale Card
struct FlashSaleCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: product.imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.05))
                    }

                    if let discount = product.discount {
                        Text("-\(discount)%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.accent)
                            .offset(x: 4, y: 4)
                    }
                }
            }
            .frame(height: 110)
            .background(Color.gray.opacity(0.05))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.accent)

                if let original = product.formattedOriginalPrice {
                    Text(original)
                        .font(.caption2)
                        .strikethrough()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(width: 110)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Hot Ranking Card
struct HotRankingCard: View {
    let product: Product
    let rank: Int
    let isLarge: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: isLarge ? 120 : 70)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                }

                Text("\(rank)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: isLarge ? 20 : 16, height: isLarge ? 20 : 16)
                    .background(rankColor)
                    .clipShape(Circle())
                    .padding(4)
            }
            .frame(height: isLarge ? 120 : 70)

            VStack(alignment: .leading, spacing: isLarge ? 6 : 2) {
                Text(product.name)
                    .font(isLarge ? .subheadline : .caption)
                    .fontWeight(.semibold)
                    .lineLimit(isLarge ? 2 : 1)
                    .foregroundStyle(Color(.label))

                Text("已售 " + product.formattedSalesCount)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(product.formattedPrice)
                    .font(isLarge ? .subheadline : .caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.29))
            }
            .padding(DesignSystem.Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color.orange
        case 2: return Color.gray
        case 3: return Color.brown.opacity(0.7)
        default: return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - Recommend Card
struct RecommendCard: View {
    @EnvironmentObject private var authManager: LoginView
    let product: Product
    let onSelect: () -> Void
    @State private var isFavorite = false
    @State private var favoriteId: String? = nil
    @State private var toast: String? = nil
    @State private var showLogin = false
    @State private var isTogglingFavorite = false

    init(product: Product, onSelect: @escaping () -> Void = {}) {
        self.product = product
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onSelect)

                Button(action: toggleFavorite) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground).opacity(0.9))
                            .frame(width: 28, height: 28)

                        if isTogglingFavorite {
                            ProgressView()
                                .scaleEffect(0.55)
                        } else {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.caption)
                                .foregroundStyle(isFavorite ? .red : .gray)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isTogglingFavorite)
                .padding(6)
            }
            .frame(height: 160)

            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Color(.label))

                Spacer()

                HStack {
                    Text(product.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.accent)

                    Spacer()

                    Text(product.salesCountText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .frame(height: 70)
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .toast($toast, bottomPadding: 24)
        .sheet(isPresented: $showLogin) {
            LoginFormView()
                .environmentObject(authManager)
        }
        .task {
            await loadFavoriteState()
        }
    }

    private func toggleFavorite() {
        guard authManager.isAuthenticated else {
            showLogin = true
            return
        }
        guard !isTogglingFavorite else { return }
        if isFavorite, let favId = favoriteId {
            isFavorite = false
            favoriteId = nil
            isTogglingFavorite = true
            Task {
                defer { isTogglingFavorite = false }
                do {
                    try await FavoriteProduct.removeFavorite(id: favId)
                    toast = "已取消收藏"
                } catch {
                    isFavorite = true
                    favoriteId = favId
                    toast = userFacingErrorMessage(error, fallback: "取消收藏失败")
                }
            }
        } else if !isFavorite {
            isFavorite = true
            isTogglingFavorite = true
            Task {
                defer { isTogglingFavorite = false }
                do {
                    favoriteId = try await FavoriteProduct.addFavorite(productId: product.id)
                    toast = "已收藏"
                } catch {
                    isFavorite = false
                    toast = userFacingErrorMessage(error, fallback: "收藏失败")
                }
            }
        }
    }

    private func loadFavoriteState() async {
        guard authManager.isAuthenticated else { return }
        do {
            let state = try await FavoriteProduct.checkFavorite(productId: product.id)
            isFavorite = state.isFavorited
            favoriteId = state.favoriteId
        } catch {
            isFavorite = false
            favoriteId = nil
        }
    }
}

// MARK: - Category Grid View
struct CategoryGridView: View {
    @State private var categories: [Category] = []
    @State private var isLoading = true
    @State private var hasLoadedRemoteCategories = false

    let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
    ]

    var body: some View {
        Group {
            if isLoading {
                SkeletonCategoryGrid()
            } else if !categories.isEmpty {
                LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
                    ForEach(categories) { category in
                        CategoryGridItem(category: category)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .task {
            guard !hasLoadedRemoteCategories else { return }
            hasLoadedRemoteCategories = true
            defer { isLoading = false }
            do {
                let remoteCategories = try await CategoryAPI.getCategories()
                if !remoteCategories.isEmpty {
                    categories = remoteCategories
                } else {
                    categories = Category.all
                }
            } catch {
                categories = Category.all
            }
        }
    }
}

struct CategoryGridItem: View {
    let category: Category
    @EnvironmentObject private var appNavigation: AppNavigation

    var body: some View {
        Button(action: {
            appNavigation.pendingCategoryId = category.id
            appNavigation.selectedTab = .category
        }) {
            VStack(spacing: 8) {
                categoryIcon
                    .frame(width: 44, height: 44)

                Text(category.name)
                    .font(.caption)
                    .foregroundStyle(Color(.label))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var categoryIcon: some View {
        if category.iconName.hasPrefix("http"), let url = URL(string: category.iconName) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    fallbackIcon
                case .empty:
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .overlay(ProgressView().scaleEffect(0.6))
                @unknown default:
                    fallbackIcon
                }
            }
        } else if !category.iconName.isEmpty {
            Image(category.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            fallbackIcon
        }
    }

    private var fallbackIcon: some View {
        Circle()
            .fill(DesignSystem.Colors.accent.opacity(0.1))
            .overlay(
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.accent)
            )
    }
}

// MARK: - Skeleton Views
struct SkeletonBanner: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 180)
                .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
}

struct SkeletonCategoryGrid: View {
    let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
            ForEach(0..<8, id: \.self) { _ in
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 44, height: 44)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 30, height: 12)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

struct SkeletonPromotionStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 82, height: 20)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 260, height: 92)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }
}

struct SkeletonFlashSale: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 20)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 110, height: 110)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 60, height: 16)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 40, height: 12)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }
}

struct SkeletonNewArrival: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 82, height: 20)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 0) {
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 138, height: 150)
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 112, height: 14)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 72, height: 16)
                            }
                            .padding(DesignSystem.Spacing.sm)
                        }
                        .frame(width: 138)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }
}

struct SkeletonHotRanking: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 20)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            VStack(spacing: DesignSystem.Spacing.sm) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 120)
                    .padding(.horizontal, DesignSystem.Spacing.md)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 70)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }
}

struct SkeletonRecommend: View {
    let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 80, height: 20)
                .padding(.horizontal, DesignSystem.Spacing.md)

            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.sm) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 0) {
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 160)
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 14)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 80, height: 14)
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 50, height: 16)
                                Spacer()
                            }
                        }
                        .padding(DesignSystem.Spacing.sm)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
}
