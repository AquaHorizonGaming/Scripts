import Foundation

class CheckoutViewModel: ObservableObject {
    @Published var address: String = ""
    @Published var scheduledDate: Date = Date()
    // TODO: integrate CoreLocation for auto-detecting address or map pin selection
    @Published var isProcessing = false
    @Published var lastOrder: Order?

    func checkout(cart: CartViewModel) async {
        guard !cart.items.isEmpty else { return }
        isProcessing = true
        do {
            let order = try await APIService.shared.checkout(cartItems: cart.items, address: address, scheduledDate: scheduledDate)
            DispatchQueue.main.async {
                self.lastOrder = order
                self.isProcessing = false
                cart.clear()
            }
        } catch {
            DispatchQueue.main.async { self.isProcessing = false }
            print("Checkout error: \(error)")
        }
    }
}
