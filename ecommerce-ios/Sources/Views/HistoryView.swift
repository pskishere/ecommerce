import SwiftUI

struct HistoryView: View {
    @State private var products: [Product] = []
    @State private var isLoading = true
    @State private var showClearAlert = false

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)
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
            } else if products.isEmpty {
                emptyView
            } else {
                productGrid
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("浏览足迹")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .alert("清空浏览记录", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                products.removeAll()
            }
        } message: {
            Text("确定要清空所有浏览记录吗？")
        }
        .task {
            await loadHistory()
        }
    }

    private var headerBar: some View {
        HStack {
            Text("\(products.count)件商品")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: { showClearAlert = true }) {
                Text("清空")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(products) { product in
                    HistoryCard(product: product)
                }
            }
            .padding(12)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("暂无浏览记录")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadHistory() async {
        isLoading = false
    }
}

struct HistoryCard: View {
    let product: Product

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(destination: ProductDetailView(product: product)) {
                AsyncImage(url: product.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(height: 160)
                }
            }
            .frame(height: 160)

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

#Preview {
    NavigationStack {
        HistoryView()
    }
}