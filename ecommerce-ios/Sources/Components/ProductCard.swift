import SwiftUI

struct ProductCard: View {
    let product: Product
    @State private var isFavorite = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            infoSection
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 8,
            x: 0,
            y: 2
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(DesignSystem.Animation.snappy, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Image Section
    private var imageSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Image(product.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                if let discount = product.discount {
                    Text("-\(discount)%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DesignSystem.Colors.accent)
                        )
                        .padding(DesignSystem.Spacing.sm)
                }

                favoriteButton
                    .padding(DesignSystem.Spacing.sm)
            }
        }
        .frame(height: 160)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: DesignSystem.Radius.lg,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: DesignSystem.Radius.lg
                )
            )
        )
    }

    // MARK: - Favorite Button
    private var favoriteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isFavorite.toggle()
            }
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.body)
                .foregroundStyle(isFavorite ? DesignSystem.Colors.accent : .gray)
                .padding(6)
                .background(
                    Circle()
                        .fill(Color(.systemBackground).opacity(0.9))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
        }
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(product.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.label))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: DesignSystem.Spacing.xs)

            bottomRow
        }
        .padding(DesignSystem.Spacing.sm)
        .frame(minHeight: 88, alignment: .top)
    }

    // MARK: - Bottom Row
    private var bottomRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            priceRow

            HStack(spacing: 4) {
                salesCountView

                Spacer()

                ratingView
            }
        }
    }

    // MARK: - Price Row
    private var priceRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(product.formattedPrice)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.accent)

            if let originalPrice = product.formattedOriginalPrice {
                Text(originalPrice)
                    .font(.caption)
                    .strikethrough()
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Rating View
    private var ratingView: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.0))

            Text(String(format: "%.1f", product.rating))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    // MARK: - Sales Count View
    private var salesCountView: some View {
        Text(product.formattedSalesCount + " sold")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Accessibility
    private var accessibilityDescription: String {
        var desc = "\(product.name), price \(product.formattedPrice)"
        if let discount = product.discount {
            desc += ", \(discount) percent off"
        }
        desc += ", \(product.formattedSalesCount) sold"
        desc += product.isInStock ? ", in stock" : ", sold out"
        return desc
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        ProductCard(product: Product.allProducts[0])
        ProductCard(product: Product.allProducts[1])
        ProductCard(product: Product.allProducts[2])
        ProductCard(product: Product.allProducts[3])
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
