import Foundation

class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []

    var total: Double {
        items.reduce(0) { $0 + $1.product.price * Double($1.quantity) }
    }

    func add(product: Product) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(product: product, quantity: 1))
        }
    }

    func remove(product: Product) {
        items.removeAll { $0.product.id == product.id }
    }

    func updateQuantity(for product: Product, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.product.id == product.id }) else { return }
        items[index].quantity = quantity
    }

    func clear() {
        items.removeAll()
    }
}
