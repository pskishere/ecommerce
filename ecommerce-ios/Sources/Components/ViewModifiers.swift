import SwiftUI

// MARK: - Hide Tab Bar Modifier
struct HideTabBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .tabBar)
    }
}

extension View {
    func hideTabBar() -> some View {
        modifier(HideTabBar())
    }
}
