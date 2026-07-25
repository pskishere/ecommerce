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
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.separator)
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
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(tab.label)
                        .font(.system(size: 14, weight: selectedTab == tab.value ? .semibold : .medium))
                        .foregroundStyle(selectedTab == tab.value ? accentColor : DesignSystem.Colors.gray1)

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
            .frame(height: 52)
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
