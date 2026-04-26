import SwiftUI

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 5
    @State private var reviewText = ""
    @State private var isAnonymous = false
    @State private var images: [String] = []

    let product: Product

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    // Product Info
                    productSection

                    // Rating Section
                    ratingSection

                    // Review Text Section
                    reviewTextSection

                    // Photos Section
                    photosSection
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))

            // Bottom Bar
            bottomBar
        }
        .navigationTitle("商品评价")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
    }

    // MARK: - Product Section
    private var productSection: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 70, height: 70)
                .overlay(
                    AsyncImage(url: product.imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.clear
                    }
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .lineLimit(2)

                Text("黑色经典款")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white)
    }

    // MARK: - Rating Section
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("描述相符")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.label))

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: { rating = star }) {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(star <= rating ? Color(hex: "FFB800") : Color(.systemGray5))
                    }
                }
                Spacer()
            }

            Text(ratingText)
                .font(.system(size: 13))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
    }

    private var ratingText: String {
        switch rating {
        case 1: return "非常差"
        case 2: return "比较差"
        case 3: return "一般"
        case 4: return "比较满意"
        case 5: return "非常满意"
        default: return ""
        }
    }

    // MARK: - Review Text Section
    private var reviewTextSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("评价内容")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.label))
                .padding(12)
                .padding(.bottom, 0)

            ZStack(alignment: .topLeading) {
                if reviewText.isEmpty {
                    Text("分享您的购物体验，帮助更多小伙伴~")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $reviewText)
                    .font(.system(size: 14))
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 12)

            Text("\(reviewText.count)/500")
                .font(.system(size: 12))
                .foregroundStyle(Color(.tertiaryLabel))
                .padding(.trailing, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Divider()
                .padding(.horizontal, 12)

            // Anonymous Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("匿名评价")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.label))
                    Text("匿名后其他用户看不到您的昵称")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(.secondaryLabel))
                }

                Spacer()

                Toggle("", isOn: $isAnonymous)
                    .labelsHidden()
                    .tint(accentColor)
            }
            .padding(12)
        }
        .background(Color.white)
    }

    // MARK: - Photos Section
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("上传图片（选填）")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.label))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Add Photo Button
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(.tertiaryLabel))
                            Text("添加图片")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .frame(width: 70, height: 70)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    ForEach(images, id: \.self) { image in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(Color(.secondaryLabel))
                            )
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: submitReview) {
                Text("提交评价")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 1.0, green: 0.91, blue: 0.88))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }

    private func submitReview() {
        // Submit review logic
        dismiss()
    }
}

#Preview {
    Text("ReviewView Preview")
}