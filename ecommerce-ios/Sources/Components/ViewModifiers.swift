import SwiftUI

// MARK: - Hide Tab Bar Modifier
struct HideTabBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Toast Modifier
private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let bottomPadding: CGFloat

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let msg = message {
                Text(msg)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
                    .padding(.bottom, bottomPadding)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { message = nil }
                        }
                    }
            }
        }
        .animation(.spring(duration: 0.35), value: message != nil)
    }
}

extension View {
    func hideTabBar() -> some View {
        modifier(HideTabBar())
    }

    func toast(_ message: Binding<String?>, bottomPadding: CGFloat = 100) -> some View {
        modifier(ToastModifier(message: message, bottomPadding: bottomPadding))
    }
}
