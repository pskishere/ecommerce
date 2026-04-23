import SwiftUI

struct CategoryView: View {
    @State private var selectedCategoryIndex = 0
    @EnvironmentObject private var cart: Cart

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            NavigationLink(destination: SearchView()) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                    Text("搜索商品")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)

            Divider()

            // Main Content
            HStack(spacing: 0) {
                categorySidebar
                categoryContent
            }
        }
        .navigationTitle("分类")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Product.self) { product in
            ProductDetailView(product: product)
        }
    }

    // MARK: - Category Sidebar
    private var categorySidebar: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(Product.categoryPages.enumerated()), id: \.element.id) { index, category in
                    CategorySidebarItem(
                        name: category.name,
                        isSelected: index == selectedCategoryIndex
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedCategoryIndex = index
                        }
                    }
                }
            }
        }
        .frame(width: 88)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Category Content
    private var categoryContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                CategoryBanner(imageName: Product.categoryPages[selectedCategoryIndex].bannerName)

                subcategoriesSection

                productListSection
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
    }

    // MARK: - Subcategories Section
    private var subcategoriesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("\(Product.categoryPages[selectedCategoryIndex].name)分类")
                .font(.subheadline)
                .fontWeight(.bold)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
            ], spacing: DesignSystem.Spacing.md) {
                ForEach(Product.categoryPages[selectedCategoryIndex].subcategories, id: \.self) { sub in
                    SubCategoryItem(name: sub, iconName: Product.categoryPages[selectedCategoryIndex].iconName)
                }
            }
        }
    }

    // MARK: - Product List Section
    private var productListSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("热门商品")
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.vertical, DesignSystem.Spacing.md)

            VStack(spacing: DesignSystem.Spacing.lg) {
                ForEach(Product.categoryPages[selectedCategoryIndex].products) { product in
                    NavigationLink(value: product) {
                        CategoryProductRow(product: product)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Category Sidebar Item
struct CategorySidebarItem: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Spacer()
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? DesignSystem.Colors.accent : Color(.label))
                .padding(.vertical, 16)
            Spacer()
        }
        .frame(height: 52)
        .background(
            Rectangle()
                .fill(isSelected ? Color(.systemBackground) : Color.clear)
        )
        .overlay(
            Rectangle()
                .fill(isSelected ? DesignSystem.Colors.accent : Color.clear)
                .frame(width: 3)
                .frame(maxHeight: .infinity)
                .offset(x: -1),
            alignment: .leading
        )
    }
}

// MARK: - Category Banner
struct CategoryBanner: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
    }
}

// MARK: - Sub Category Item
struct SubCategoryItem: View {
    let name: String
    let iconName: String

    var body: some View {
        VStack(spacing: 6) {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)

            Text(name)
                .font(.caption2)
                .foregroundStyle(Color(.label))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Product Row
struct CategoryProductRow: View {
    let product: Product
    @EnvironmentObject private var cart: Cart

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(product.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm))

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Spacer()

                HStack {
                    Text(product.formattedPrice)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.accent)

                    Spacer()

                    Button(action: {
                        cart.addToCart(product)
                    }) {
                        Image(systemName: "plus")
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(DesignSystem.Colors.accent)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .frame(height: 110)
    }
}

#Preview {
    CategoryView()
        .environmentObject(Cart())
}
