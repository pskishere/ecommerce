import SwiftUI

struct CategoryView: View {
    @State private var categories: [Category] = []
    @State private var selectedCategoryIndex = 0
    @State private var categoryProducts: [String: [Product]] = [:]
    @State private var categorySubcategories: [String: [String]] = [:]
    @State private var isLoading = true
    @EnvironmentObject private var cart: Cart

    var body: some View {
        VStack(spacing: 0) {
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
        .task {
            await loadData()
        }
    }

    // MARK: - Category Sidebar
    private var categorySidebar: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
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
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if selectedCategoryIndex < categories.count {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    CategoryBanner(imageName: categories[selectedCategoryIndex].bannerName)
                    subcategoriesSection
                    productListSection
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
    }

    // MARK: - Subcategories Section
    @ViewBuilder
    private var subcategoriesSection: some View {
        if selectedCategoryIndex < categories.count {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("\(categories[selectedCategoryIndex].name)分类")
                    .font(.subheadline)
                    .fontWeight(.bold)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                ], spacing: DesignSystem.Spacing.md) {
                    ForEach(categories[selectedCategoryIndex].subcategories, id: \.self) { sub in
                        SubCategoryItem(name: sub, iconName: categories[selectedCategoryIndex].iconName)
                    }
                }
            }
        }
    }

    // MARK: - Product List Section
    @ViewBuilder
    private var productListSection: some View {
        let categoryId = selectedCategoryIndex < categories.count ? categories[selectedCategoryIndex].id : ""
        let products = categoryProducts[categoryId] ?? []

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("热门商品")
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.vertical, DesignSystem.Spacing.md)

            if products.isEmpty {
                Text("暂无商品")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            } else {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    ForEach(products) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            CategoryProductRow(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true
        do {
            let allCategories = try await CategoryAPI.getCategories()
            categories = allCategories

            // Load subcategories with products for each category
            for category in categories {
                let subcategories = try await CategoryAPI.getCategorySubcategories(categoryId: category.id)
                var allProducts: [Product] = []
                var subcatNames: [String] = []
                for sub in subcategories {
                    subcatNames.append(sub.name)
                    allProducts.append(contentsOf: sub.products)
                }
                categoryProducts[category.id] = allProducts
                // Store subcategory names if needed
                if !subcatNames.isEmpty {
                    categorySubcategories[category.id] = subcatNames
                }
            }
        } catch {
            print("Failed to load categories: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Category with Subcategories Model
struct CategoryWithSubcategories: Codable {
    let id: String
    let name: String
    let image: String?
    let sortOrder: Int
    let isEnabled: Bool
    let products: [Product]

    enum CodingKeys: String, CodingKey {
        case id, name, image, products
        case sortOrder = "sort_order"
        case isEnabled = "is_enabled"
    }
}

// MARK: - Category API
enum CategoryAPI {
    static func getCategories() async throws -> [Category] {
        try await APIClient.shared.request(endpoint: APIEndpoints.categories, requiresAuth: false)
    }

    static func getCategorySubcategories(categoryId: String) async throws -> [CategoryWithSubcategories] {
        try await APIClient.shared.request(
            endpoint: "categories/\(categoryId)/subcategories/",
            requiresAuth: false
        )
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
        AsyncImage(url: URL(string: imageName)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 100)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 100)
        }
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
            AsyncImage(url: product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 110, height: 110)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 110, height: 110)
            }
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