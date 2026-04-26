import SwiftUI

struct FavoritesView: View {
    @State private var favorites: [FavoriteProduct] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    private let shopAccentColor = DesignSystem.Colors.accent
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
        .background(Color(hex: "F5F5F5"))
        .navigationTitle("我的收藏")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .task {
            do {
                favorites = try await FavoriteProduct.getFavorites()
            } catch {
                print("Failed to load favorites: \(error)")
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
                        onRemove: { Task { await removeFavorite(product) } }
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

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func removeFavorite(_ product: FavoriteProduct) async {
        do {
            try await FavoriteProduct.removeFavorite(id: product.id)
            favorites.removeAll { $0.id == product.id }
        } catch {
            print("Failed to remove favorite: \(error)")
        }
    }
}

// MARK: - Favorite Card
struct FavoriteCard: View {
    let product: FavoriteProduct
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .aspectRatio(3/4, contentMode: .fill)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color(hex: "F8F8F8"))
                }

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

                    Text("已售 \(product.sales)")
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

#Preview {
    NavigationStack {
        FavoritesView()
    }
}
