import SwiftUI

struct CategoryView: View {
    @State private var categories: [Category] = []
    @State private var selectedCategoryIndex = 0
    @State private var categoryProducts: [String: [Product]] = [:]
    @State private var categorySubcategories: [String: [String]] = [:]
    @State private var categorySubcategoryIcons: [String: [String]] = [:]
    @State private var isLoading = true
    @State private var toast: String? = nil
    @EnvironmentObject private var cart: Cart
    private let contentTopInset: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            H5SearchNav(placeholder: "搜索商品")

            if isLoading {
                categorySkeletonLayout
            } else if categories.isEmpty {
                categoryEmptyState
            } else {
                HStack(spacing: 0) {
                    categorySidebar
                    categoryContent
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Colors.light)
        .toolbar(.hidden, for: .navigationBar)
        .toast($toast, bottomPadding: 96)
        .navigationDestination(for: Product.self) { product in
            ProductDetailView(product: product)
        }
        .task {
            await loadData()
        }
    }

    private var categoryEmptyState: some View {
        AppEmptyState(
            systemImage: "square.grid.2x2",
            title: "分类加载失败",
            message: "暂时没有拿到分类数据，请稍后重试",
            actionTitle: "重试",
            action: {
                Task { await loadData() }
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    // MARK: - Category Sidebar
    @ViewBuilder
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
        .frame(maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Category Content
    @ViewBuilder
    private var categoryContent: some View {
        ScrollView {
            if isLoading {
                categoryContentSkeleton
                .padding(.horizontal, 12)
                .padding(.top, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            } else if selectedCategoryIndex < categories.count {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    CategoryBanner(imageName: categories[selectedCategoryIndex].bannerName)
                    subcategoriesSection
                    productListSection
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }

    // MARK: - Category Skeleton Layout
    private var categorySkeletonLayout: some View {
        HStack(spacing: 0) {
            categorySidebarSkeleton

            categoryContentSkeleton
                .padding(.horizontal, 12)
                .padding(.top, contentTopInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var categorySidebarSkeleton: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: contentTopInset)

            ForEach(0..<9, id: \.self) { index in
                HStack {
                    CategorySkeletonBlock(width: index == 0 ? 42 : 50, height: 14, cornerRadius: 5)
                }
                .frame(width: 88, height: 52)
                .background(index == 0 ? Color.white : Color.clear)
                .overlay(
                    Rectangle()
                        .fill(index == 0 ? DesignSystem.Colors.accent : Color.clear)
                        .frame(width: 3),
                    alignment: .leading
                )
            }
            Spacer(minLength: 0)
        }
        .frame(width: 88)
        .frame(maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Category Content Skeleton
    private var categoryContentSkeleton: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Banner skeleton
            CategorySkeletonBlock(height: 100, cornerRadius: 10)
                .frame(maxWidth: .infinity)

            // Subcategories skeleton
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                CategorySkeletonBlock(width: 84, height: 16, cornerRadius: 5)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                ], spacing: DesignSystem.Spacing.md) {
                    ForEach(0..<6, id: \.self) { _ in
                        VStack(spacing: 6) {
                            CategorySkeletonBlock(width: 56, height: 56, cornerRadius: 10)
                            CategorySkeletonBlock(width: 40, height: 12, cornerRadius: 4)
                        }
                    }
                }
            }

            // Product list skeleton
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                CategorySkeletonBlock(width: 84, height: 16, cornerRadius: 5)
                    .padding(.vertical, DesignSystem.Spacing.md)

                ForEach(0..<3, id: \.self) { _ in
                    CategoryProductRowSkeleton()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Subcategories Section
    @ViewBuilder
    private var subcategoriesSection: some View {
        let categoryId = selectedCategoryIndex < categories.count ? categories[selectedCategoryIndex].id : ""
        let subcatNames = categorySubcategories[categoryId] ?? []
        let subcatIcons = categorySubcategoryIcons[categoryId] ?? []

        if !subcatNames.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("\(categories[selectedCategoryIndex].name)分类")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .padding(.vertical, 8)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                ], spacing: DesignSystem.Spacing.md) {
                    ForEach(Array(subcatNames.enumerated()), id: \.offset) { index, sub in
                        NavigationLink(destination: SearchView(initialQuery: sub)) {
                            SubCategoryItem(name: sub, iconURL: subcatIcons.indices.contains(index) ? subcatIcons[index] : nil, fallbackIconURL: categories[selectedCategoryIndex].iconName)
                        }
                        .buttonStyle(.plain)
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
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.dark)
                .padding(.vertical, 8)

            if products.isEmpty {
                Text("暂无商品")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(products) { product in
                        ZStack(alignment: .bottomTrailing) {
                            NavigationLink(value: product) {
                                CategoryProductRow(product: product)
                            }
                            .buttonStyle(.plain)

                            Button(action: { addProductToCart(product) }) {
                                Image(systemName: "plus")
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(DesignSystem.Colors.accent)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 12)
                            .padding(.bottom, 12)
                        }
                    }
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true
        do {
            categoryProducts = [:]
            categorySubcategories = [:]
            categorySubcategoryIcons = [:]
            let allCategories = try await CategoryAPI.getCategories()
            categories = allCategories
            selectedCategoryIndex = min(selectedCategoryIndex, max(allCategories.count - 1, 0))

            try await withThrowingTaskGroup(of: (String, [CategoryWithSubcategories]).self) { group in
                for category in allCategories {
                    group.addTask {
                        let subs = try await CategoryAPI.getCategorySubcategories(categoryId: category.id)
                        return (category.id, subs)
                    }
                }
                for try await (categoryId, subcategories) in group {
                    var allProducts: [Product] = []
                    var subcatNames: [String] = []
                    var subcatIcons: [String] = []
                    for sub in subcategories {
                        subcatNames.append(sub.name)
                        subcatIcons.append(sub.image ?? "")
                        allProducts.append(contentsOf: sub.products)
                    }
                    categoryProducts[categoryId] = allProducts
                    if !subcatNames.isEmpty {
                        categorySubcategories[categoryId] = subcatNames
                        categorySubcategoryIcons[categoryId] = subcatIcons
                    }
                }
            }
        } catch {
            toast = userFacingErrorMessage(error, fallback: "分类加载失败")
        }
        isLoading = false
    }

    private func addProductToCart(_ product: Product) {
        Task {
            do {
                try await cart.addToCart(product)
                toast = "已加入购物车"
            } catch {
                toast = userFacingErrorMessage(error, fallback: "加入购物车失败")
            }
        }
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
                .font(.system(size: 13, weight: .medium))
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.gray1)
                .padding(.vertical, 16)
            Spacer()
        }
        .frame(height: 52)
        .background(
            Rectangle()
                .fill(isSelected ? Color.white : Color.clear)
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
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Sub Category Item
struct SubCategoryItem: View {
    let name: String
    let iconURL: String?
    let fallbackIconURL: String?

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignSystem.Colors.light)
                    .frame(width: 56, height: 56)

                subCategoryIcon
                    .frame(width: 36, height: 36)
            }

            Text(name)
                .font(.system(size: 11))
                .foregroundStyle(DesignSystem.Colors.dark)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var preferredIconName: String {
        [iconURL, fallbackIconURL]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    @ViewBuilder
    private var subCategoryIcon: some View {
        if preferredIconName.hasPrefix("http"), let url = URL(string: preferredIconName) {
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
        } else if !preferredIconName.isEmpty {
            Image(preferredIconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            fallbackIcon
        }
    }

    private var fallbackIcon: some View {
        Circle()
            .fill(DesignSystem.Colors.accent.opacity(0.12))
            .overlay(
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.accent)
            )
    }
}

// MARK: - Category Product Row
struct CategoryProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 88, height: 88)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 88, height: 88)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(DesignSystem.Colors.dark)

                Spacer()

                HStack {
                    Text(product.formattedPrice)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    Spacer()
                }
                .padding(.trailing, 44)
            }
        }
        .padding(12)
        .background(DesignSystem.Colors.light)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Category Product Row Skeleton
struct CategoryProductRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            CategorySkeletonBlock(width: 88, height: 88, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 8) {
                CategorySkeletonBlock(width: 130, height: 16, cornerRadius: 5)
                CategorySkeletonBlock(width: 92, height: 14, cornerRadius: 5)
                Spacer()
                HStack {
                    CategorySkeletonBlock(width: 64, height: 20, cornerRadius: 6)
                    Spacer()
                    CategorySkeletonBlock(width: 32, height: 32, cornerRadius: 16)
                }
            }
        }
        .padding(12)
        .frame(height: 112)
        .background(DesignSystem.Colors.light)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct CategorySkeletonBlock: View {
    var width: CGFloat? = nil
    let height: CGFloat
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(hex: "E8E9EF"))
            .frame(width: width, height: height)
            .shimmer()
    }
}

#Preview {
    CategoryView()
        .environmentObject(Cart())
}
