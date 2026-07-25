import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var authManager: LoginView
    @State private var shopInfo: ShopInfo?
    @State private var products: [Product] = []
    @State private var selectedTab = "全部商品"
    @State private var isLoading = true
    @State private var isFollowing = UserDefaults.standard.bool(forKey: "shop_following")
    @State private var toast: String?
    @State private var showLogin = false

    private let tabs = ["全部商品", "新品上架", "热卖宝贝"]
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                shopHeader
                shopStats
                tabBar
                productGrid
            }
            .padding(.bottom, 24)
        }
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle("店铺")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .toast($toast, bottomPadding: 24)
        .sheet(isPresented: $showLogin) {
            LoginFormView()
                .environmentObject(authManager)
        }
        .task {
            await loadShop()
        }
    }

    private var shopHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: mediaURL("banner-1-summer-1710.webp"))) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 146)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color(hex: "ECEEF2"))
                    .frame(height: 146)
                    .shimmer()
            }

            HStack(alignment: .center, spacing: 12) {
                AsyncImage(url: URL(string: mediaURL("product-01-watch.webp"))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 58, height: 58)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "F2F2F2"))
                        .frame(width: 58, height: 58)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 5) {
                    Text(shopInfo?.name ?? "潮流优品官方旗舰店")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.dark)
                        .lineLimit(1)

                    Text(shopInfo?.description ?? "专注年轻人日常穿搭、数码配件与品质生活好物")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.gray1)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                ShareLink(item: shopShareURL) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.dark)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "F5F5F5"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: toggleFollow) {
                    HStack(spacing: 4) {
                        Image(systemName: isFollowing ? "heart.fill" : "heart")
                            .font(.system(size: 12, weight: .semibold))
                        Text(isFollowing ? "已关注" : "关注")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(isFollowing ? DesignSystem.Colors.accent : .white)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(isFollowing ? DesignSystem.Colors.accentSoft : DesignSystem.Colors.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }

    private var shopStats: some View {
        HStack(spacing: 0) {
            statItem(value: shopInfo?.score ?? "4.9", label: "综合评分")
            statItem(value: "\(shopInfo?.productCount ?? products.count)", label: "在售商品")
            statItem(value: shopInfo?.sales ?? "0", label: "累计销量")
            statItem(value: shopInfo?.fansCount ?? "0", label: "粉丝")
        }
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 12)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(DesignSystem.Colors.dark)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(DesignSystem.Colors.gray2)
        }
        .frame(maxWidth: .infinity)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 7) {
                        Text(tab)
                            .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundStyle(selectedTab == tab ? DesignSystem.Colors.accent : DesignSystem.Colors.gray1)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(selectedTab == tab ? DesignSystem.Colors.accent : Color.clear)
                            .frame(width: 18, height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white)
    }

    @ViewBuilder
    private var productGrid: some View {
        if isLoading {
            ShopProductGridSkeleton()
                .padding(.horizontal, 12)
        } else if filteredProducts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 42))
                    .foregroundStyle(DesignSystem.Colors.gray3)
                Text("暂无商品")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignSystem.Colors.gray2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 52)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredProducts) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ShopProductCard(product: product)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private var filteredProducts: [Product] {
        switch selectedTab {
        case "新品上架":
            return Array(products.reversed())
        case "热卖宝贝":
            return products.sorted { $0.salesCount > $1.salesCount }
        default:
            return products
        }
    }

    private var shopShareURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:5173/shop.html")!
        #else
        return URL(string: "https://handsome-youth-production-98c5.up.railway.app/shop.html")!
        #endif
    }

    private func toggleFollow() {
        guard authManager.isAuthenticated else {
            showLogin = true
            return
        }
        isFollowing.toggle()
        UserDefaults.standard.set(isFollowing, forKey: "shop_following")
        toast = isFollowing ? "关注成功" : "已取消关注"
    }

    private func loadShop() async {
        isLoading = true
        async let infoTask = ShopInfo.getInfo()
        async let productsTask = ShopInfo.getProducts()
        do {
            shopInfo = try await infoTask
            products = try await productsTask
        } catch {
            toast = "店铺加载失败"
        }
        isLoading = false
    }

    private func mediaURL(_ fileName: String) -> String {
        #if DEBUG
        return "http://localhost:8080/media/uploads/\(fileName)"
        #else
        return "https://handsome-youth-production-98c5.up.railway.app/media/uploads/\(fileName)"
        #endif
    }
}

private struct ShopProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 164)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color(hex: "F3F4F6"))
                    .frame(height: 164)
                    .shimmer()
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .lineLimit(2)
                    .frame(height: 36, alignment: .top)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(product.formattedPrice)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    if let original = product.formattedOriginalPrice {
                        Text(original)
                            .font(.system(size: 11))
                            .foregroundStyle(DesignSystem.Colors.gray2)
                            .strikethrough()
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "FFB800"))
                    Text(String(format: "%.1f", product.rating))
                        .font(.system(size: 11))
                        .foregroundStyle(DesignSystem.Colors.gray2)
                    Spacer()
                    Text(product.salesCountText)
                        .font(.system(size: 11))
                        .foregroundStyle(DesignSystem.Colors.gray2)
                }
            }
            .padding(10)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}

private struct ShopProductGridSkeleton: View {
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "ECEEF2"))
                        .frame(height: 164)
                        .shimmer()
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "ECEEF2"))
                        .frame(height: 14)
                        .shimmer()
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "ECEEF2"))
                        .frame(width: 90, height: 14)
                        .shimmer()
                }
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShopView()
    }
    .environmentObject(Cart())
    .environmentObject(LoginView.shared)
}
