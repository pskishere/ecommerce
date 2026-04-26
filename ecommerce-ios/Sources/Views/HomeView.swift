import SwiftUI

struct HomeView: View {
    @State private var banners: [Banner] = []
    @State private var flashSaleProducts: [Product] = []
    @State private var hotRankingProducts: [Product] = []
    @State private var recommendedProducts: [Product] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                if isLoading {
                    skeletonContent
                } else {
                    heroBanner
                    categoryGrid
                    flashSaleSection
                    hotRankingsSection
                    recommendSection
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .navigationTitle("潮流好物")
        .task {
            await loadData()
        }
    }

    // MARK: - Skeleton Loading Content
    private var skeletonContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            SkeletonBanner()
            SkeletonCategoryGrid()
            SkeletonFlashSale()
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

                Button(action: {}) {
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
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            FlashSaleCard(product: product)
                        }
                        .buttonStyle(.plain)
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

                Button(action: {}) {
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
                if hotRankingProducts.count > 0 {
                    NavigationLink(destination: ProductDetailView(product: hotRankingProducts[0])) {
                        HotRankingCard(product: hotRankingProducts[0], rank: 1, isLarge: true)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(1...min(3, hotRankingProducts.count - 1), id: \.self) { index in
                            NavigationLink(destination: ProductDetailView(product: hotRankingProducts[index])) {
                                HotRankingCard(product: hotRankingProducts[index], rank: index + 1, isLarge: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
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
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        RecommendCard(product: product)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }

    // MARK: - Data Loading
    private func loadData() async {
        isLoading = true
        do {
            async let bannersTask = Product.getBanners()
            async let flashTask = Product.getFlashSaleProducts()
            async let hotTask = Product.getHotRankingProducts()
            async let recommendTask = Product.getRecommendProducts()

            banners = try await bannersTask
            flashSaleProducts = try await flashTask
            hotRankingProducts = try await hotTask
            recommendedProducts = try await recommendTask
        } catch {
            print("Failed to load home data: \(error)")
        }
        isLoading = false
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

#Preview {
    HomeView()
        .environmentObject(Cart())
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

                    Button(action: {}) {
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
    let product: Product
    @State private var isFavorite = false

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

                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundStyle(isFavorite ? .red : .gray)
                        .padding(5)
                        .background(Color(.systemBackground).opacity(0.9))
                        .clipShape(Circle())
                }
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
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Category Grid View
struct CategoryGridView: View {
    let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
            ForEach(Category.all) { category in
                CategoryGridItem(category: category)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

struct CategoryGridItem: View {
    let category: Category

    var body: some View {
        VStack(spacing: 8) {
            Image(category.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)

            Text(category.name)
                .font(.caption)
                .foregroundStyle(Color(.label))
        }
        .frame(maxWidth: .infinity)
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
