import SwiftUI

@main
struct ShopApp: App {
    @StateObject private var cart = Cart()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cart)
        }
    }
}
