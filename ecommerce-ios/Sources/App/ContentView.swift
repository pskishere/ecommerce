import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = LoginView.shared
    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView()
                .tag(MainTab.home)
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }

            CategoryTabView()
                .tag(MainTab.category)
                .tabItem {
                    Label("分类", systemImage: "square.grid.2x2")
                }

            CartTabView(authManager: authManager)
                .tag(MainTab.cart)
                .tabItem {
                    Label("购物车", systemImage: "bag.fill")
                }

            ProfileTabView(authManager: authManager)
                .tag(MainTab.profile)
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
        }
        .tint(DesignSystem.Colors.accent)
        .environmentObject(authManager)
    }
}

// MARK: - Tab Wrappers with NavigationStack
struct HomeTabView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

struct CategoryTabView: View {
    var body: some View {
        NavigationStack {
            CategoryView()
        }
    }
}

struct CartTabView: View {
    @ObservedObject var authManager: LoginView
    @State private var showCheckout = false
    @State private var showLogin = false
    @StateObject private var cart = Cart()

    var body: some View {
        NavigationStack {
            Group {
                if authManager.isAuthenticated {
                    CartView(showCheckout: $showCheckout)
                        .environmentObject(cart)
                        .navigationDestination(isPresented: $showCheckout) {
                            CheckoutView()
                        }
                } else {
                    LoginPromptView(onLogin: { showLogin = true })
                        .sheet(isPresented: $showLogin) {
                            LoginFormView()
                                .environmentObject(authManager)
                        }
                }
            }
        }
    }
}

struct ProfileTabView: View {
    @ObservedObject var authManager: LoginView
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            Group {
                if authManager.isAuthenticated {
                    ProfileView()
                        .navigationDestination(for: Order.self) { order in
                            OrderDetailView(order: order)
                        }
                } else {
                    LoginPromptView(onLogin: { showLogin = true })
                        .sheet(isPresented: $showLogin) {
                            LoginFormView()
                                .environmentObject(authManager)
                        }
                }
            }
        }
    }
}

// MARK: - Login Prompt View
struct LoginPromptView: View {
    let onLogin: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 80))
                .foregroundStyle(.gray.opacity(0.4))

            Text("请先登录")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)

            Text("登录后可享受更多功能")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Button(action: onLogin) {
                Text("登录")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 48)
                    .background(DesignSystem.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Login Prompt for Actions
struct LoginRequiredModifier: ViewModifier {
    @ObservedObject var authManager: LoginView
    let onShowLogin: () -> Void

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if !authManager.isAuthenticated {
                    onShowLogin()
                }
            }
    }
}

enum MainTab: String, CaseIterable {
    case home
    case category
    case cart
    case profile

    var title: String {
        switch self {
        case .home: return "首页"
        case .category: return "分类"
        case .cart: return "购物车"
        case .profile: return "我的"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .category: return "square.grid.2x2"
        case .cart: return "bag.fill"
        case .profile: return "person.fill"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Cart())
}