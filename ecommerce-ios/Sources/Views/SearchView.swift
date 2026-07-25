import SwiftUI

struct SearchView: View {
    private let initialQuery: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchHistory: [String] = []
    @State private var showResults = false
    @State private var searchResults: [Product] = []
    @State private var isSearching = false
    @State private var didRunInitialSearch = false
    @State private var didLoadHotTags = false
    @State private var hotTags: [String] = []
    @State private var searchError: String? = nil


    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    init(initialQuery: String? = nil) {
        self.initialQuery = initialQuery
        _searchText = State(initialValue: initialQuery ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            searchHeader

            if showResults {
                searchResultsView
            } else {
                searchContent
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .hideTabBar()
        .onAppear {
            loadHistory()
            if !didRunInitialSearch,
               let initialQuery,
               !initialQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                didRunInitialSearch = true
                performSearch()
            }
        }
        .task {
            await loadHotTags()
        }
    }

    // MARK: - Search Header
    private var searchHeader: some View {
        HStack(spacing: 8) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .frame(width: 34, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Search Box
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.tertiaryLabel))

                TextField("搜索商品、品牌", text: $searchText)
                    .font(.system(size: 14))
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Color(.systemGray6))
            .clipShape(Capsule())

            // Search Button
            Button(action: performSearch) {
                Text("搜索")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.accent)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .background(Color(red: 1.0, green: 0.94, blue: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Search Content (Hot Tags + History)
    private var searchContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hot Tags Section
                hotTagsSection

                // Search History Section
                if !searchHistory.isEmpty {
                    searchHistorySection
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Hot Tags Section
    private var hotTagsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("热门搜索")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(.label))
                .padding(.horizontal, 12)

            if hotTags.isEmpty {
                Text("暂无热门搜索")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.horizontal, 12)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70, maximum: .infinity), spacing: 8)], spacing: 8) {
                    ForEach(hotTags, id: \.self) { tag in
                        Button(action: {
                            searchText = tag
                            performSearch()
                        }) {
                            Text(tag)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(.label))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Search History Section
    private var searchHistorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("搜索历史")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(.label))
                .padding(.horizontal, 12)
                .padding(.top, 8)

            VStack(spacing: 0) {
                ForEach(searchHistory.prefix(10), id: \.self) { term in
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(.systemGray4))

                        Text(term)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(.darkGray))
                            .lineLimit(1)

                        Spacer()

                        Button(action: {
                            deleteHistory(term)
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(.systemGray4))
                                .padding(4)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)

                    Divider()
                        .padding(.leading, 36)
                }
            }

            // Clear History Button
            Button(action: clearAllHistory) {
                Text("清空搜索历史")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Search Results
    private var searchResultsView: some View {
        ScrollView {
            if isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
            } else if let searchError {
                Text(searchError)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else if searchResults.isEmpty {
                Text("未找到相关商品")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(searchResults) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            resultCard(product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
        }
    }

    private func resultCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .lineLimit(2)

                Text(product.formattedPrice)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.accent)
            }
            .padding(10)
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Actions
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        addToHistory(query)
        showResults = true
        Task {
            isSearching = true
            searchError = nil
            do {
                searchResults = try await Product.searchProducts(query: query)
            } catch {
                searchError = userFacingErrorMessage(error, fallback: "搜索失败，请稍后重试")
                searchResults = []
            }
            isSearching = false
        }
    }

    private func loadHotTags() async {
        guard !didLoadHotTags else { return }
        didLoadHotTags = true

        do {
            async let categoriesTask = CategoryAPI.getCategories()
            async let productsTask = Product.getProducts()
            let categories = try await categoriesTask
            let products = try await productsTask

            var tags: [String] = []
            func appendTag(_ raw: String?) {
                let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !value.isEmpty, !tags.contains(value) else { return }
                tags.append(value)
            }

            for product in products.sorted(by: { $0.salesCount > $1.salesCount }) {
                appendTag(product.subcategoryRef?.name)
                if tags.count >= 10 { break }
            }

            for category in categories {
                appendTag(category.name)
                for subcategory in category.subcategories {
                    appendTag(subcategory)
                    if tags.count >= 10 { break }
                }
                if tags.count >= 10 { break }
            }

            if tags.count < 6 {
                for product in products.sorted(by: { $0.salesCount > $1.salesCount }) {
                    appendTag(product.name)
                    if tags.count >= 10 { break }
                }
            }

            hotTags = Array(tags.prefix(10))
        } catch {
            hotTags = []
        }
    }

    private func addToHistory(_ term: String) {
        searchHistory.removeAll { $0 == term }
        searchHistory.insert(term, at: 0)
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        saveHistory()
    }

    private func deleteHistory(_ term: String) {
        searchHistory.removeAll { $0 == term }
        saveHistory()
    }

    private func clearAllHistory() {
        searchHistory.removeAll()
        saveHistory()
    }

    private func loadHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: "searchHistory") ?? []
    }

    private func saveHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "searchHistory")
    }
}

#Preview {
    SearchView()
        .environmentObject(Cart())
}
