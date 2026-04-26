import SwiftUI

struct ReviewsView: View {
    let product: Product
    @StateObject private var viewModel = ReviewsViewModel()

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

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
        .background(Color(.systemGroupedBackground))
        .navigationTitle("全部评价")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
    }

    // MARK: - Header Summary
    private var headerSummary: some View {
        HStack(spacing: 16) {
            // Score
            VStack(spacing: 2) {
                Text(String(format: "%.1f", product.rating))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(accentColor)

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
                .foregroundStyle(viewModel.selectedFilter == tag ? .white : accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(viewModel.selectedFilter == tag ? accentColor : Color(red: 1.0, green: 0.94, blue: 0.92))
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

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

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
                        .foregroundStyle(accentColor)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: review.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                        Text("\(review.likeCount)")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(review.isLiked ? accentColor : .secondary)
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
                    .foregroundStyle(review.isLiked ? accentColor : .secondary)
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
class ReviewsViewModel: ObservableObject {
    @Published var selectedFilter = "全部"
    @Published var selectedTab = "全部"
    @Published var showWithImages = false
    @Published var showWithVideos = false
    @Published var reviews: [ProductReview]

    init() {
        reviews = [
            ProductReview(id: UUID(), userName: "用户小王", rating: 5, content: "非常满意！手表外观简约大气，表带佩戴舒适，走时精准。包装也很精美，送礼自用都很合适。", spec: "黑色 / M码", date: "2026-03-25", images: ["photo"], hasReply: true, replyText: "感谢您的支持，欢迎再次光临~", likeCount: 12, isLiked: false),
            ProductReview(id: UUID(), userName: "潮流达人", rating: 5, content: "超级喜欢这款手表，简约风格很百搭，性价比超高！", spec: "黑色 / L码", date: "2026-03-24", images: [], hasReply: false, likeCount: 8, isLiked: true),
            ProductReview(id: UUID(), userName: "品质生活", rating: 4, content: "整体不错，就是表带稍微有点硬，不过戴几天就好了。", spec: "棕色 / M码", date: "2026-03-23", images: ["photo", "photo"], hasReply: true, replyText: "感谢您的反馈，表带会越戴越贴合的~", likeCount: 3, isLiked: false),
            ProductReview(id: UUID(), userName: "购物达人", rating: 5, content: "第三次购买了，品质一如既往的好，物流也很快，好评！", spec: "黑色 / S码", date: "2026-03-22", images: [], hasReply: false, likeCount: 15, isLiked: false),
            ProductReview(id: UUID(), userName: "时尚博主", rating: 3, content: "还行吧，没有想象中那么满意，表盘有点小。", spec: "黑色 / M码", date: "2026-03-21", images: [], hasReply: false, likeCount: 1, isLiked: false)
        ]
    }

    var filteredReviews: [ProductReview] {
        var result = reviews

        // Filter by tab (star rating)
        switch selectedTab {
        case "5星":
            result = result.filter { $0.rating == 5 }
        case "4星":
            result = result.filter { $0.rating == 4 }
        case "3星":
            result = result.filter { $0.rating == 3 }
        case "1-2星":
            result = result.filter { $0.rating <= 2 }
        default:
            break
        }

        // Filter by images
        if selectedFilter == "有图" {
            result = result.filter { !$0.images.isEmpty }
        }

        return result
    }
}

#Preview {
    Text("ReviewsView Preview")
}
