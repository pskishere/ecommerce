import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var appNavigation: AppNavigation
    @State private var favorites: [FavoriteProduct] = []
    @State private var isLoading = true
    @State private var toast: String? = nil
    @State private var favoriteToRemove: FavoriteProduct?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if favorites.isEmpty {
                emptyView
            } else {
                productGrid
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle("我的收藏")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .navigationDestination(for: Product.self) { product in
            ProductDetailView(product: product)
        }
        .alert("取消收藏", isPresented: Binding(
            get: { favoriteToRemove != nil },
            set: { if !$0 { favoriteToRemove = nil } }
        )) {
            Button("保留", role: .cancel) { favoriteToRemove = nil }
            Button("取消收藏", role: .destructive) {
                if let product = favoriteToRemove {
                    Task { await removeFavorite(product) }
                }
                favoriteToRemove = nil
            }
        } message: {
            Text("确定要从收藏中移除这个商品吗？")
        }
        .toast($toast, bottomPadding: 80)
        .task {
            do {
                favorites = try await FavoriteProduct.getFavorites()
            } catch {
                toast = userFacingErrorMessage(error, fallback: "收藏加载失败")
            }
            isLoading = false
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            Text("\(favorites.count)件商品")
                .font(.system(size: 13))
                .foregroundStyle(Color(.secondaryLabel))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    // MARK: - Product Grid
    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(favorites) { product in
                    FavoriteCard(
                        product: product,
                        onRemove: { favoriteToRemove = product }
                    )
                }
            }
            .padding(12)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "F5F5F5"))
                    .frame(width: 80, height: 80)

                Image(systemName: "heart.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "CCCCCC"))
            }

            Text("暂无收藏商品")
                .font(.system(size: 14))
                .foregroundStyle(Color(.secondaryLabel))

            Button(action: { appNavigation.selectedTab = .category }) {
                Text("去逛逛")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 42)
                    .background(DesignSystem.Colors.accent)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func removeFavorite(_ product: FavoriteProduct) async {
        do {
            try await FavoriteProduct.removeFavorite(id: product.id)
            favorites.removeAll { $0.id == product.id }
            toast = "已取消收藏"
        } catch {
            toast = userFacingErrorMessage(error, fallback: "取消收藏失败")
        }
    }
}

// MARK: - Favorite Card
struct FavoriteCard: View {
    let product: FavoriteProduct
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: product.asProduct) {
                VStack(alignment: .leading, spacing: 0) {
                    productImage
                    productInfo
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 28, height: 28)

                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(8)
        }
    }

    private var productImage: some View {
        AsyncImage(url: product.imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color(hex: "F8F8F8"))
        }
        .aspectRatio(3/4, contentMode: .fit)
    }

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "1A1A1A"))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text(product.price.rmbText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "0F766E"))

                Spacer()

                Text("已售 \(product.sales)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "999999"))
            }
        }
        .padding(10)
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environmentObject(AppNavigation())
}
