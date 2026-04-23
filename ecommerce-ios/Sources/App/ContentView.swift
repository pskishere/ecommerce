import SwiftUI

struct ContentView: View {
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

            CartTabView()
                .tag(MainTab.cart)
                .tabItem {
                    Label("购物车", systemImage: "bag.fill")
                }

            ProfileTabView()
                .tag(MainTab.profile)
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
        }
        .tint(DesignSystem.Colors.accent)
    }
}

// MARK: - Tab Wrappers with NavigationStack
struct HomeTabView: View {
    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: Product.self) { product in
                    ProductDetailView(product: product)
                }
        }
    }
}

struct CategoryTabView: View {
    var body: some View {
        NavigationStack {
            CategoryView()
                .navigationDestination(for: Product.self) { product in
                    ProductDetailView(product: product)
                }
        }
    }
}

struct CartTabView: View {
    @State private var showCheckout = false

    var body: some View {
        NavigationStack {
            CartView(showCheckout: $showCheckout)
                .navigationDestination(isPresented: $showCheckout) {
                    CheckoutView()
                }
        }
    }
}

struct ProfileTabView: View {
    var body: some View {
        NavigationStack {
            ProfileView()
                .navigationDestination(for: Order.self) { order in
                    OrderDetailView(order: order)
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