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
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 32
    }

    // MARK: Colors
    enum Colors {
        static let accent = Color(hex: "FF6B4A")
        static let accentDark = Color(hex: "E85A3A")
        static let accentLight = Color(hex: "FF8A6A")
        static let accentSoft = Color(hex: "FFF0ED")
        static let dark = Color(hex: "1A1A1A")
        static let dark2 = Color(hex: "2D2D2D")
        static let gray1 = Color(hex: "666666")
        static let gray2 = Color(hex: "999999")
        static let gray3 = Color(hex: "CCCCCC")
        static let gray4 = Color(hex: "E5E5E5")
        static let light = Color(hex: "F8F8F8")
        static let pageBackground = Color(hex: "F5F5F5")
        static let surface = Color.white
        static let background = Color.white
        static let secondaryBackground = Color(hex: "F8F8F8")
        static let tertiaryBackground = Color(hex: "F2F2F2")
        static let text = Color(hex: "1A1A1A")
        static let secondaryText = Color(hex: "666666")
        static let tertiaryText = Color(hex: "999999")
        static let separator = Color.black.opacity(0.06)
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - H5-Aligned Shared UI
struct H5SearchNav: View {
    let placeholder: String
    let searchDestination: SearchView
    let trailing: AnyView

    init(placeholder: String = "搜索", searchDestination: SearchView = SearchView()) {
        self.placeholder = placeholder
        self.searchDestination = searchDestination
        self.trailing = AnyView(EmptyView())
    }

    init<Trailing: View>(
        placeholder: String = "搜索",
        searchDestination: SearchView = SearchView(),
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.placeholder = placeholder
        self.searchDestination = searchDestination
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: searchDestination) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.gray2)

                    Text(placeholder)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.gray2)

                    Spacer()
                }
                .frame(height: 36)
                .padding(.horizontal, 14)
                .background(Color(hex: "F2F2F2"))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            trailing
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

struct H5IconButton: View {
    let systemName: String
    var badge: Int? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.dark)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())

                if let badge, badge > 0 {
                    Text("\(min(badge, 99))")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .frame(minWidth: 15, minHeight: 15)
                        .padding(.horizontal, 2)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                        .offset(x: 2, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct H5PageHeader: View {
    let title: String
    var showsBackButton: Bool = true
    let trailing: AnyView
    @Environment(\.dismiss) private var dismiss

    init(title: String, showsBackButton: Bool = true) {
        self.title = title
        self.showsBackButton = showsBackButton
        self.trailing = AnyView(EmptyView())
    }

    init<Trailing: View>(
        title: String,
        showsBackButton: Bool = true,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.showsBackButton = showsBackButton
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if showsBackButton {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.dark)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.dark)
                .frame(maxWidth: .infinity)

            trailing
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

struct H5Section<Content: View>: View {
    var horizontalPadding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
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

// MARK: - Shared State Views
struct AppEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.gray2.opacity(0.55))
                .frame(width: 72, height: 72)
                .background(Color.white.opacity(0.72))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.dark)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(DesignSystem.Colors.gray2)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 40)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(TactileButtonStyle())
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}

struct AppInlineLoadingView: View {
    var title: String = "加载中"

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.85)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.gray2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
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
