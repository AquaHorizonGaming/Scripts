import SwiftUI

struct MainTabView: View {
    @StateObject private var cartViewModel = CartViewModel()
    @StateObject private var productListViewModel = ProductListViewModel()
    @StateObject private var orderHistoryViewModel = OrderHistoryViewModel()

    var body: some View {
        TabView {
            ProductListView()
                .environmentObject(productListViewModel)
                .environmentObject(cartViewModel)
                .tabItem { Label("Shop", systemImage: "cart") }
            CartView()
                .environmentObject(cartViewModel)
                .tabItem { Label("Cart", systemImage: "cart.fill") }
            OrderHistoryView()
                .environmentObject(orderHistoryViewModel)
                .tabItem { Label("Orders", systemImage: "clock") }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
