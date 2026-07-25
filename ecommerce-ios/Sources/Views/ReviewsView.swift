import SwiftUI

struct ReviewsView: View {
    let product: Product
    @StateObject private var viewModel = ReviewsViewModel()


    var body: some View {
        VStack(spacing: 0) {
            // Header Summary
            headerSummary

            // Filter Tabs
            filterTabs

            // Reviews List
            if viewModel.filteredReviews.isEmpty {
                emptyView
            } else {
                reviewsList
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle("全部评价")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .toast($viewModel.errorMessage, bottomPadding: 80)
        .task { await viewModel.load(productId: product.id) }
    }

    // MARK: - Header Summary
    private var headerSummary: some View {
        HStack(spacing: 16) {
            // Score
            VStack(spacing: 2) {
                Text(String(format: "%.1f", product.rating))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.accent)

                Text("综合评分")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70)

            // Tags
            VStack(alignment: .leading, spacing: 6) {
                FlowLayout(spacing: 6) {
                    ForEach(["全部", "好评", "中评", "差评", "有图"], id: \.self) { tag in
                        filterTag(tag)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.white)
    }

    private func filterTag(_ tag: String) -> some View {
        Button(action: { viewModel.selectedFilter = tag }) {
            Text(tag)
                .font(.system(size: 12))
                .foregroundStyle(viewModel.selectedFilter == tag ? .white : DesignSystem.Colors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(viewModel.selectedFilter == tag ? DesignSystem.Colors.accent : Color(red: 1.0, green: 0.94, blue: 0.92))
                .clipShape(Capsule())
        }
    }

    // MARK: - Filter Tabs
    private var filterTabs: some View {
        ContentTab(
            tabs: [
                ContentTabItem(value: "全部", label: "全部"),
                ContentTabItem(value: "5星", label: "5星"),
                ContentTabItem(value: "4星", label: "4星"),
                ContentTabItem(value: "3星", label: "3星"),
                ContentTabItem(value: "1-2星", label: "1-2星"),
            ],
            selectedTab: $viewModel.selectedTab
        )
    }

    // MARK: - Reviews List
    private var reviewsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredReviews) { review in
                    ReviewCard(review: review)
                }
            }
            .padding(12)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("暂无评价")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Review Card
struct ReviewCard: View {
    let review: ProductReview


    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(star <= review.rating ? Color.orange : Color.gray.opacity(0.3))
                        }
                    }
                }

                Spacer()

                Text(review.date)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            // Spec
            if !review.spec.isEmpty {
                Text("规格：" + review.spec)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            // Content
            Text(review.content)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .lineSpacing(2)

            // Images
            if !review.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(review.images, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                }
            }

            // Footer (reply)
            if review.hasReply {
                HStack {
                    Text("商家回复：\(review.replyText)")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: review.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                        Text("\(review.likeCount)")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(review.isLiked ? DesignSystem.Colors.accent : .secondary)
                }
                .padding(.top, 8)
            } else {
                HStack {
                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: review.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                        Text("\(review.likeCount)")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(review.isLiked ? DesignSystem.Colors.accent : .secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Flow Layout
struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50, maximum: .infinity), spacing: spacing)], spacing: spacing) {
            content()
        }
    }
}

// MARK: - Product Review
struct ProductReview: Identifiable {
    let id: UUID
    let userName: String
    let rating: Int
    let content: String
    let spec: String
    let date: String
    let images: [String]
    var isAnonymous: Bool = false
    var hasReply: Bool = false
    var replyText: String = ""
    var likeCount: Int = 0
    var isLiked: Bool = false
}

// MARK: - Reviews ViewModel
@MainActor
class ReviewsViewModel: ObservableObject {
    @Published var selectedFilter = "全部"
    @Published var selectedTab = "全部"
    @Published var reviews: [ProductReview] = []
    @Published var errorMessage: String? = nil

    func load(productId: String) async {
        do {
            let items = try await Product.getReviews(id: productId)
            errorMessage = nil
            reviews = items.map { r in
                ProductReview(
                    id: UUID(),
                    userName: r.userName,
                    rating: r.rating,
                    content: r.content,
                    spec: r.spec,
                    date: r.createdAt.flatMap { String($0.prefix(10)) } ?? "",
                    images: r.images,
                    hasReply: false
                )
            }
        } catch {
            reviews = []
            errorMessage = userFacingErrorMessage(error, fallback: "评价加载失败")
        }
    }

    var filteredReviews: [ProductReview] {
        var result = reviews
        switch selectedTab {
        case "5星": result = result.filter { $0.rating == 5 }
        case "4星": result = result.filter { $0.rating == 4 }
        case "3星": result = result.filter { $0.rating == 3 }
        case "1-2星": result = result.filter { $0.rating <= 2 }
        default: break
        }
        if selectedFilter == "有图" {
            result = result.filter { !$0.images.isEmpty }
        }
        return result
    }
}

#Preview {
    Text("ReviewsView Preview")
}
