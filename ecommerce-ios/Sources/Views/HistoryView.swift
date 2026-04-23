import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)
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
        .background(Color(.systemGroupedBackground))
        .navigationTitle("浏览足迹")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            Text("\(viewModel.products.count)件商品")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: { viewModel.showClearAlert = true }) {
                Text("清空")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .alert("清空浏览记录", isPresented: $viewModel.showClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                viewModel.clearHistory()
            }
        } message: {
            Text("确定要清空所有浏览记录吗？")
        }
    }

    // MARK: - Product Grid
    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.products) { product in
                    HistoryCard(product: product)
                }
            }
            .padding(12)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("暂无浏览记录")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Button(action: {}) {
                Text("去逛逛")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(accentColor)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - History Card
struct HistoryCard: View {
    let product: Product

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(destination: ProductDetailView(product: product)) {
                Image(product.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
            }
            .frame(height: 160)
            .background(Color.gray.opacity(0.05))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                HStack {
                    Text(product.formattedPrice)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(accentColor)

                    Spacer()

                    Text(product.salesCountText)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .frame(height: 60)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - History ViewModel
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var showClearAlert = false
    @Published var isLoading: Bool = false

    init() {
        Task {
            await loadHistory()
        }
    }

    func loadHistory() async {
        isLoading = true
        // Currently using all products as placeholder
        // Full implementation would use User.getHistory() which returns HistoryItem
        products = Product.allProducts
        isLoading = false
    }

    func clearHistory() {
        Task {
            _ = await User.clearHistory()
            products.removeAll()
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
