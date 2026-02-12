import Foundation

class OrderHistoryViewModel: ObservableObject {
    @Published var orders: [Order] = []

    func loadHistory() async {
        do {
            let orders = try await APIService.shared.fetchOrderHistory()
            DispatchQueue.main.async {
                self.orders = orders
            }
        } catch {
            print("Order history error: \(error)")
        }
    }
}
