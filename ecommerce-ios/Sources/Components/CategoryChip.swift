import SwiftUI

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    private let accentColor = DesignSystem.Colors.accent

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(category.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)

                Text(category.name)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? accentColor : Color(.label))
        }
        .buttonStyle(.plain)
        .animation(DesignSystem.Animation.snappy, value: isSelected)
    }
}

#Preview {
    HStack {
        CategoryChip(category: Category.all[0], isSelected: true) {}
        CategoryChip(category: Category.all[1], isSelected: false) {}
    }
}
