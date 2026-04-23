import SwiftUI

// MARK: - Design System Constants
enum DesignSystem {
    // MARK: Spacing (8pt grid)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: Colors
    enum Colors {
        static let accent = Color(red: 1.0, green: 0.27, blue: 0.23)
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        static let text = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        static let separator = Color(.separator)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }

    // MARK: Shadows
    enum Shadow {
        static let sm = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let md = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let xl = (color: Color.black.opacity(0.16), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
    }

    // MARK: Animation
    enum Animation {
        static let snappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
}

// MARK: - Environment Key for Reduce Motion
private struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var prefersReducedMotion: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}

// MARK: - Glass Card Modifier
struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                colorScheme == .dark
                    ? Color.black.opacity(0.3)
                    : Color.white.opacity(0.72)
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
            .shadow(
                color: DesignSystem.Shadow.md.color,
                radius: DesignSystem.Shadow.md.radius,
                x: DesignSystem.Shadow.md.x,
                y: DesignSystem.Shadow.md.y
            )
    }
}

// MARK: - Tactile Button Style
struct TactileButtonStyle: ButtonStyle {
    let hapticIntensity: CGFloat

    init(hapticIntensity: CGFloat = 0.5) {
        self.hapticIntensity = hapticIntensity
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 20) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
            .fill(Color.gray.opacity(0.15))
            .frame(width: width, height: height)
            .shimmer()
    }
}
