import SwiftUI

struct BannerLandingView: View {
    let banner: Banner
    @State private var landing: BannerLanding?
    @State private var selectedProduct: Product?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var toast: String?

    private let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
    ]

    var body: some View {
        ScrollView {
            if isLoading {
                skeletonContent
            } else if let loadError {
                AppEmptyState(
                    systemImage: "wifi.exclamationmark",
                    title: "专题加载失败",
                    message: loadError,
                    actionTitle: "重试",
                    action: {
                        Task { await loadLanding() }
                    }
                )
                .padding(.top, 120)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            } else if let landing {
                content(landing)
            }
        }
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle((landing?.tag.isEmpty == false ? landing?.tag : banner.tag) ?? "专题会场")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product)
        }
        .toast($toast, bottomPadding: 36)
        .task {
            await loadLanding()
        }
    }

    private func content(_ landing: BannerLanding) -> some View {
        VStack(spacing: 0) {
            hero(landing)
            intro(landing)
            productSection(landing)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.bottom, DesignSystem.Spacing.xl)
    }

    private func hero(_ landing: BannerLanding) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: landing.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    LinearGradient(
                        colors: landing.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .frame(width: proxy.size.width, height: 290)
                .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.02),
                        Color.black.opacity(0.42)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: proxy.size.width, height: 290)

                VStack(alignment: .leading, spacing: 10) {
                    Text(landing.badgeText)
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 24)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())

                    Text(landing.title.isEmpty ? banner.title : landing.title)
                        .font(.system(size: 31, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(landing.subtitleText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(2)
                }
                .padding(DesignSystem.Spacing.lg)
                .frame(width: proxy.size.width, alignment: .bottomLeading)
            }
        }
        .frame(height: 290)
        .clipped()
    }

    private func intro(_ landing: BannerLanding) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(landing.landingDescription.isEmpty ? "精选商品已为你整理好，可直接浏览并加入购物车。" : landing.landingDescription)
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.gray1)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: DesignSystem.Spacing.sm) {
                CampaignBenefit(title: "官方精选")
                CampaignBenefit(title: "7天无理由")
                CampaignBenefit(title: "满99包邮")
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .padding(.horizontal, DesignSystem.Spacing.md)
        .offset(y: -18)
        .padding(.bottom, -18)
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
    }

    private func productSection(_ landing: BannerLanding) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("会场商品")
                    .font(.headline)
                    .fontWeight(.black)

                Spacer()

                Text("\(landing.products.count) 件精选")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            if landing.products.isEmpty {
                AppEmptyState(
                    systemImage: "shippingbox",
                    title: "商品正在补货",
                    message: "当前专题还没有绑定商品",
                    actionTitle: nil,
                    action: nil
                )
                .padding(.vertical, DesignSystem.Spacing.xl)
            } else {
                LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.sm) {
                    ForEach(landing.products) { product in
                        Button(action: { selectedProduct = product }) {
                            CampaignProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var skeletonContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.gray.opacity(0.12))
                .frame(height: 290)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 120, height: 14)
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 240, height: 14)
            }
            .padding(DesignSystem.Spacing.md)
            .background(Color(.systemBackground))
            .padding(.horizontal, DesignSystem.Spacing.md)

            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 250)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }

    private func loadLanding() async {
        isLoading = true
        loadError = nil
        do {
            landing = try await Product.getBannerLanding(id: banner.id)
        } catch {
            let message = userFacingErrorMessage(error, fallback: "专题数据加载失败")
            loadError = message
            toast = message
        }
        isLoading = false
    }
}

private struct CampaignBenefit: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(DesignSystem.Colors.accent)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(DesignSystem.Colors.accentSoft)
            .clipShape(Capsule())
    }
}

private struct CampaignProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline) {
                    Text(product.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.black)
                        .foregroundStyle(DesignSystem.Colors.accent)

                    Spacer(minLength: 4)

                    Text(product.salesCountText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .frame(minHeight: 92, alignment: .top)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
