import PhotosUI
import SwiftUI
import UIKit

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 5
    @State private var reviewText = ""
    @State private var isAnonymous = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImageData: [Data] = []
    @State private var toast: String?
    @State private var isSubmitting = false

    let product: Product


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
        .toast($toast, bottomPadding: 80)
        .onChange(of: reviewText) { _, value in
            if value.count > 500 {
                reviewText = String(value.prefix(500))
                toast = "评价最多500字"
            }
        }
        .onChange(of: selectedPhotoItems) { _, items in
            Task { await loadSelectedImages(items) }
        }
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

                Text(product.description.isEmpty ? "默认规格" : product.description)
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
                    .tint(DesignSystem.Colors.accent)
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
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: 6,
                        matching: .images
                    ) {
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
                    .disabled(selectedImageData.count >= 6)

                    ForEach(Array(selectedImageData.enumerated()), id: \.offset) { index, data in
                        ZStack(alignment: .topTrailing) {
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundStyle(Color(.secondaryLabel))
                                    )
                            }

                            Button(action: {
                                selectedImageData.remove(at: index)
                                selectedPhotoItems = []
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 18, height: 18)
                                    .background(Color.black.opacity(0.55))
                                    .clipShape(Circle())
                            }
                            .offset(x: 5, y: -5)
                        }
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
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.75)
                            .tint(DesignSystem.Colors.accent)
                    }
                    Text(isSubmitting ? "提交中..." : "提交评价")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(DesignSystem.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(red: 1.0, green: 0.91, blue: 0.88))
                .clipShape(Capsule())
            }
            .disabled(isSubmitting)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }

    private func submitReview() {
        guard !reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            toast = "请填写评价内容"
            return
        }
        guard !isSubmitting else { return }
        isSubmitting = true
        let imagePayloads = selectedImageData.map { data in
            "data:image/jpeg;base64,\(data.base64EncodedString())"
        }
        Task {
            defer { isSubmitting = false }
            do {
                try await Product.createReview(
                    productId: product.id,
                    rating: rating,
                    content: reviewText.trimmingCharacters(in: .whitespacesAndNewlines),
                    isAnonymous: isAnonymous,
                    images: imagePayloads
                )
                dismiss()
            } catch {
                toast = userFacingErrorMessage(error, fallback: "评价提交失败")
            }
        }
    }

    private func loadSelectedImages(_ items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        var failedCount = 0
        for item in items.prefix(6) {
            guard let rawData = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: rawData),
                  let jpegData = image.jpegData(compressionQuality: 0.82) else {
                failedCount += 1
                continue
            }
            loaded.append(jpegData)
        }
        await MainActor.run {
            selectedImageData = loaded
            if failedCount > 0 {
                toast = "部分图片读取失败"
            } else if items.count > 6 {
                toast = "最多选择6张图片"
            }
        }
    }
}

#Preview {
    Text("ReviewView Preview")
}
