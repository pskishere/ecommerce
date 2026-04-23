import SwiftUI

// MARK: - Content Tab Item Model
struct ContentTabItem: Hashable, Equatable {
    let value: String
    let label: String
    var badgeCount: Int? = nil
}

// MARK: - Content Tab View
struct ContentTab: View {
    let tabs: [ContentTabItem]
    @Binding var selectedTab: String
    var accentColor: Color = DesignSystem.Colors.accent

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private func tabButton(_ tab: ContentTabItem) -> some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.snappy) {
                selectedTab = tab.value
            }
        }) {
            VStack(spacing: 10) {
                HStack(spacing: 4) {
                    Text(tab.label)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(selectedTab == tab.value ? accentColor : Color(.secondaryLabel))

                    if let count = tab.badgeCount, count > 0 {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 8, height: 8)
                    }
                }

                Rectangle()
                    .fill(accentColor)
                    .frame(width: 12, height: 3)
                    .clipShape(Capsule())
                    .opacity(selectedTab == tab.value ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentTab(
        tabs: [
            ContentTabItem(value: "all", label: "全部", badgeCount: 3),
            ContentTabItem(value: "order", label: "订单"),
            ContentTabItem(value: "promo", label: "优惠"),
            ContentTabItem(value: "system", label: "系统"),
        ],
        selectedTab: .constant("all")
    )
}
