import SwiftUI

struct SearchView: View {
    fileprivate enum SearchSort: String, CaseIterable, Identifiable {
        case comprehensive
        case sales
        case priceAsc
        case priceDesc
        case rating

        var id: String { rawValue }

        var title: String {
            switch self {
            case .comprehensive: return "综合"
            case .sales: return "销量"
            case .priceAsc: return "价格升序"
            case .priceDesc: return "价格降序"
            case .rating: return "评分"
            }
        }

        var shortTitle: String {
            switch self {
            case .comprehensive: return "综合"
            case .sales: return "销量"
            case .priceAsc: return "低价"
            case .priceDesc: return "高价"
            case .rating: return "评分"
            }
        }
    }

    fileprivate enum SearchLayout {
        case grid
        case list
    }

    private let initialQuery: String?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    @State private var searchHistory: [String] = []
    @State private var showResults = false
    @State private var searchResults: [Product] = []
    @State private var isSearching = false
    @State private var didRunInitialSearch = false
    @State private var didLoadHotTags = false
    @State private var isLoadingHotTags = false
    @State private var hotTags: [String] = []
    @State private var productSuggestions: [String] = []
    @State private var searchError: String? = nil
    @State private var showClearHistoryConfirm = false
    @State private var resultSort: SearchSort = .comprehensive
    @State private var resultLayout: SearchLayout = .grid

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var suggestedTerms: [String] {
        guard !trimmedSearchText.isEmpty, !showResults else { return [] }
        let candidates = productSuggestions + hotTags + searchHistory
        var seen = Set<String>()
        return candidates.compactMap { term in
            let value = term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty,
                  value.localizedCaseInsensitiveContains(trimmedSearchText),
                  value.compare(trimmedSearchText, options: .caseInsensitive) != .orderedSame,
                  !seen.contains(value)
            else {
                return nil
            }
            seen.insert(value)
            return value
        }
        .prefix(6)
        .map { $0 }
    }

    private var sortedResults: [Product] {
        switch resultSort {
        case .comprehensive:
            return searchResults
        case .sales:
            return searchResults.sorted { $0.salesCount > $1.salesCount }
        case .priceAsc:
            return searchResults.sorted { $0.price < $1.price }
        case .priceDesc:
            return searchResults.sorted { $0.price > $1.price }
        case .rating:
            return searchResults.sorted {
                if $0.rating == $1.rating {
                    return $0.salesCount > $1.salesCount
                }
                return $0.rating > $1.rating
            }
        }
    }

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
        .background(DesignSystem.Colors.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .hideTabBar()
        .onChange(of: searchText) { _, value in
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showResults = false
                searchResults = []
                searchError = nil
            }
        }
        .onAppear {
            loadHistory()
            if !didRunInitialSearch,
               let initialQuery,
               !initialQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                didRunInitialSearch = true
                performSearch()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isSearchFocused = true
                }
            }
        }
        .task {
            await loadHotTags()
        }
        .alert("清空搜索历史", isPresented: $showClearHistoryConfirm) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                clearAllHistory()
            }
        } message: {
            Text("确定要清空全部搜索记录吗？")
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 8) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .frame(width: 36, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.gray2)

                TextField("搜索商品、品牌、分类", text: $searchText)
                    .focused($isSearchFocused)
                    .font(.system(size: 15, weight: .medium))
                    .submitLabel(.search)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button(action: resetSearchText) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.gray3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Color(hex: "F2F2F2"))
            .clipShape(Capsule())

            Button(action: performSearch) {
                Text(isSearching ? "搜索中" : "搜索")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(trimmedSearchText.isEmpty ? DesignSystem.Colors.gray2 : .white)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(trimmedSearchText.isEmpty ? Color(hex: "EEEEEE") : DesignSystem.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(TactileButtonStyle())
            .disabled(trimmedSearchText.isEmpty || isSearching)
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

    private var searchContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if !suggestedTerms.isEmpty {
                    suggestionsSection
                }

                hotTagsSection

                if !searchHistory.isEmpty {
                    searchHistorySection
                }

                searchInspirationSection
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var suggestionsSection: some View {
        SearchSectionCard {
            SearchSectionHeader(
                icon: "sparkle.magnifyingglass",
                title: "猜你想搜",
                subtitle: "根据当前输入补全"
            )

            VStack(spacing: 0) {
                ForEach(suggestedTerms, id: \.self) { term in
                    Button(action: { selectTerm(term) }) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.gray2)

                            Text(term)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.dark)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.gray3)
                        }
                        .frame(height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if term != suggestedTerms.last {
                        Divider()
                            .padding(.leading, 24)
                    }
                }
            }
        }
    }

    private var hotTagsSection: some View {
        SearchSectionCard {
            SearchSectionHeader(
                icon: "line.3.horizontal.decrease.circle",
                title: "热门搜索",
                subtitle: isLoadingHotTags ? "正在读取商城热度" : "来自分类和热销商品"
            )

            if isLoadingHotTags {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                    ForEach(0..<8, id: \.self) { index in
                        SkeletonView(width: index % 3 == 0 ? 96 : 72, height: 34)
                            .clipShape(Capsule())
                    }
                }
            } else if hotTags.isEmpty {
                Text("暂无热门搜索")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignSystem.Colors.gray2)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(hotTags, id: \.self) { tag in
                        SearchTokenButton(title: tag, style: .filled) {
                            selectTerm(tag)
                        }
                    }
                }
            }
        }
    }

    private var searchHistorySection: some View {
        SearchSectionCard {
            SearchSectionHeader(
                icon: "clock.arrow.circlepath",
                title: "搜索历史",
                subtitle: "保留最近 20 条"
            ) {
                Button(action: { showClearHistoryConfirm = true }) {
                    Text("清空")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.gray2)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(searchHistory.prefix(10), id: \.self) { term in
                    SearchHistoryToken(title: term) {
                        selectTerm(term)
                    } onDelete: {
                        deleteHistory(term)
                    }
                }
            }
        }
    }

    private var searchInspirationSection: some View {
        SearchSectionCard {
            SearchSectionHeader(
                icon: "square.grid.2x2.fill",
                title: "快速入口",
                subtitle: "不用输入也能继续逛"
            )

            HStack(spacing: 10) {
                NavigationLink(destination: CouponView()) {
                    SearchInspirationCard(
                        icon: "ticket.fill",
                        title: "先领券",
                        subtitle: "满减优惠"
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    if let term = hotTags.first {
                        selectTerm(term)
                    }
                }) {
                    SearchInspirationCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "搜热销",
                        subtitle: "高销量优先"
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    selectTerm("新品")
                }) {
                    SearchInspirationCard(
                        icon: "tag",
                        title: "看新品",
                        subtitle: "上新好物"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchResultsView: some View {
        ScrollView {
            if isSearching {
                SearchResultsSkeleton(layout: resultLayout)
                    .padding(12)
            } else if let searchError {
                AppEmptyState(
                    systemImage: "wifi.exclamationmark",
                    title: "搜索失败",
                    message: searchError,
                    actionTitle: "重试",
                    action: performSearch
                )
                .padding(.top, 96)
            } else if searchResults.isEmpty {
                VStack(spacing: 18) {
                    AppEmptyState(
                        systemImage: "magnifyingglass",
                        title: "未找到相关商品",
                        message: "换个关键词试试，或从热门搜索继续逛",
                        actionTitle: "返回搜索",
                        action: {
                            showResults = false
                            searchResults = []
                        }
                    )

                    if !hotTags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                            ForEach(hotTags.prefix(6), id: \.self) { tag in
                                SearchTokenButton(title: tag, style: .outline) {
                                    selectTerm(tag)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 88)
            } else {
                VStack(spacing: 12) {
                    SearchResultsToolbar(
                        query: trimmedSearchText,
                        count: sortedResults.count,
                        sort: $resultSort,
                        layout: $resultLayout
                    )

                    if resultLayout == .grid {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(sortedResults) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    SearchGridProductCard(product: product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(sortedResults) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    SearchListProductRow(product: product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.bottom, 28)
            }
        }
        .refreshable {
            await runSearch(saveToHistory: false)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func resetSearchText() {
        searchText = ""
        showResults = false
        searchResults = []
        searchError = nil
        isSearchFocused = true
    }

    private func selectTerm(_ term: String) {
        searchText = term
        performSearch()
    }

    private func performSearch() {
        Task {
            await runSearch(saveToHistory: true)
        }
    }

    @MainActor
    private func runSearch(saveToHistory: Bool) async {
        let query = trimmedSearchText
        guard !query.isEmpty else {
            showResults = false
            searchResults = []
            searchError = nil
            return
        }

        if saveToHistory {
            addToHistory(query)
        }
        showResults = true
        isSearchFocused = false
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

    @MainActor
    private func loadHotTags() async {
        guard !didLoadHotTags else { return }
        didLoadHotTags = true
        isLoadingHotTags = true
        defer { isLoadingHotTags = false }

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
            productSuggestions = Array(products.map { $0.name }.prefix(30))
        } catch {
            hotTags = []
            productSuggestions = []
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

private struct SearchSectionCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}

private struct SearchSectionHeader<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: () -> Trailing

    init(icon: String, title: String, subtitle: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    init(icon: String, title: String, subtitle: String) where Trailing == EmptyView {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = { EmptyView() }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.accent)
                .frame(width: 28, height: 28)
                .background(DesignSystem.Colors.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.dark)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.gray2)
            }

            Spacer()

            trailing()
        }
    }
}

private struct SearchTokenButton: View {
    enum Style {
        case filled
        case outline
    }

    let title: String
    var style: Style = .filled
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(style == .filled ? DesignSystem.Colors.dark : DesignSystem.Colors.accent)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(style == .filled ? Color(hex: "F6F6F6") : DesignSystem.Colors.accentSoft)
                .overlay(
                    Capsule()
                        .stroke(style == .filled ? Color.clear : DesignSystem.Colors.accent.opacity(0.25), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(TactileButtonStyle())
    }
}

private struct SearchHistoryToken: View {
    let title: String
    let action: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .medium))
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(DesignSystem.Colors.gray1)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.gray3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Color(hex: "F6F6F6"))
        .clipShape(Capsule())
    }
}

private struct SearchInspirationCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.accent)
                .frame(width: 30, height: 30)
                .background(Color.white)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.gray2)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFF7F4"), Color(hex: "F8F8F8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct SearchResultsToolbar: View {
    let query: String
    let count: Int
    @Binding var sort: SearchView.SearchSort
    @Binding var layout: SearchView.SearchLayout

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("“\(query)”")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.dark)
                        .lineLimit(1)

                    Text("找到 \(count) 件相关商品")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.gray2)
                }

                Spacer()

                SearchLayoutToggle(layout: $layout)
            }

            HStack(spacing: 8) {
                ForEach([SearchView.SearchSort.comprehensive, .sales, .priceAsc, .rating]) { option in
                    Button(action: {
                        withAnimation(DesignSystem.Animation.quick) {
                            sort = option
                        }
                    }) {
                        Text(option.shortTitle)
                            .font(.system(size: 13, weight: sort == option ? .bold : .semibold))
                            .foregroundStyle(sort == option ? .white : DesignSystem.Colors.gray1)
                            .frame(height: 32)
                            .padding(.horizontal, 12)
                            .background(sort == option ? DesignSystem.Colors.dark : Color(hex: "F2F2F2"))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Menu {
                    ForEach(SearchView.SearchSort.allCases) { option in
                        Button(action: { sort = option }) {
                            Label(option.title, systemImage: sort == option ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.gray1)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "F2F2F2"))
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.white)
    }
}

private struct SearchLayoutToggle: View {
    @Binding var layout: SearchView.SearchLayout

    var body: some View {
        HStack(spacing: 0) {
            toggleButton(icon: "square.grid.2x2", target: .grid)
            toggleButton(icon: "list.bullet", target: .list)
        }
        .padding(3)
        .background(Color(hex: "F2F2F2"))
        .clipShape(Capsule())
    }

    private func toggleButton(icon: String, target: SearchView.SearchLayout) -> some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.quick) {
                layout = target
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(layout == target ? .white : DesignSystem.Colors.gray1)
                .frame(width: 30, height: 28)
                .background(layout == target ? DesignSystem.Colors.accent : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct SearchGridProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 154)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 154)
                }

                if let discount = product.discount {
                    BadgeView(text: "-\(discount)%", color: DesignSystem.Colors.accent)
                        .padding(8)
                } else if !product.tag.isEmpty {
                    BadgeView(text: product.tag, color: Color(red: 0.18, green: 0.52, blue: 0.43))
                        .padding(8)
                }
            }
            .frame(height: 154)
            .background(Color(hex: "F7F7F7"))

            VStack(alignment: .leading, spacing: 7) {
                Text(product.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(product.formattedPrice)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    if let original = product.formattedOriginalPrice {
                        Text(original)
                            .font(.system(size: 11, weight: .medium))
                            .strikethrough()
                            .foregroundStyle(DesignSystem.Colors.gray2)
                    }
                }

                HStack(spacing: 6) {
                    SearchMetricPill(icon: "star.fill", text: String(format: "%.1f", product.rating))
                    Text(product.formattedSalesCount)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.gray2)
                }
            }
            .padding(10)
            .frame(height: 98, alignment: .topLeading)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct SearchListProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 112, height: 112)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                }

                if let discount = product.discount {
                    Text("-\(discount)%")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(6)
                }
            }
            .frame(width: 112, height: 112)
            .background(Color(hex: "F7F7F7"))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(product.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.gray2)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    SearchMetricPill(icon: "star.fill", text: String(format: "%.1f", product.rating))
                    SearchMetricPill(icon: "bag.fill", text: product.formattedSalesCount)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(product.formattedPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    if let original = product.formattedOriginalPrice {
                        Text(original)
                            .font(.system(size: 12, weight: .medium))
                            .strikethrough()
                            .foregroundStyle(DesignSystem.Colors.gray2)
                    }

                    Spacer()
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct SearchMetricPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(DesignSystem.Colors.gray1)
        .padding(.horizontal, 7)
        .frame(height: 22)
        .background(Color(hex: "F5F5F5"))
        .clipShape(Capsule())
    }
}

private struct SearchResultsSkeleton: View {
    let layout: SearchView.SearchLayout

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        if layout == .grid {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 0) {
                        SkeletonView(height: 154)
                        VStack(alignment: .leading, spacing: 8) {
                            SkeletonView(height: 14)
                            SkeletonView(width: 96, height: 14)
                            SkeletonView(width: 68, height: 18)
                        }
                        .padding(10)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        } else {
            LazyVStack(spacing: 10) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 12) {
                        SkeletonView(width: 112, height: 112)
                        VStack(alignment: .leading, spacing: 8) {
                            SkeletonView(height: 15)
                            SkeletonView(width: 180, height: 13)
                            SkeletonView(width: 124, height: 22)
                            SkeletonView(width: 96, height: 18)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(Cart())
        .environmentObject(AppNavigation())
        .environmentObject(LoginView.shared)
}
