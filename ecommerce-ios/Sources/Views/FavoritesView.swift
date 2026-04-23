import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @Environment(\.dismiss) private var dismiss

    private let shopAccentColor = Color(red: 1.0, green: 0.42, blue: 0.29)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            // Content
            if viewModel.products.isEmpty {
                emptyView
            } else {
                productGrid
            }
        }
        .background(Color(hex: "F5F5F5"))
        .navigationTitle("我的收藏")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            Text("\(viewModel.products.count)件商品")
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
                ForEach(viewModel.products) { product in
                    FavoriteCard(
                        product: product,
                        onRemove: { viewModel.removeFavorite(product) }
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

            Button(action: { dismiss() }) {
                Text("去逛逛")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(shopAccentColor)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Favorite Card
struct FavoriteCard: View {
    let product: Product
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with remove button
            ZStack(alignment: .topTrailing) {
                NavigationLink(destination: ProductDetailView(product: product)) {
                    Image(product.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .aspectRatio(3/4, contentMode: .fill)
                        .clipped()
                }

                // Remove button
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
            .background(Color(hex: "F8F8F8"))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text("¥\(product.price)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "FF6B4A"))

                    Spacer()

                    Text("已售 \(product.salesCount)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "999999"))
                }
            }
            .padding(10)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Favorites ViewModel
@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false

    init() {
        Task {
            await loadFavorites()
        }
    }

    func loadFavorites() async {
        isLoading = true
        // Currently using recommended products as placeholder
        // Full implementation would use User.getFavorites() which returns FavoriteProduct
        products = Product.recommendedProducts
        isLoading = false
    }

    func removeFavorite(_ product: Product) {
        Task {
            _ = await User.toggleFavorite(product)
            products.removeAll { $0.id == product.id }
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
}
