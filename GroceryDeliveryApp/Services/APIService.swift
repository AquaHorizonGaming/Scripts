import Foundation

class APIService {
    static let shared = APIService()
    private init() {}

    let baseURL = URL(string: "https://api.example.com")!

    func fetchCategories() async throws -> [Category] {
        // Placeholder: /categories
        return []
    }

    func fetchProducts(in categoryID: Int?) async throws -> [Product] {
        // Placeholder: /products or /categories/:id/products
        return []
    }

    func login(email: String, password: String) async throws -> User {
        // Placeholder: /login
        return User(id: 1, name: "Demo", email: email, token: nil)
    }

    func createAccount(name: String, email: String, password: String) async throws -> User {
        // Placeholder: /signup
        return User(id: 1, name: name, email: email, token: nil)
    }

    func checkout(cartItems: [CartItem], address: String, scheduledDate: Date) async throws -> Order {
        // Placeholder: /checkout
        return Order(id: Int.random(in: 1000...9999), date: Date(), items: cartItems, total: cartItems.reduce(0) { $0 + $1.product.price * Double($1.quantity) })
    }

    func fetchOrderHistory() async throws -> [Order] {
        // Placeholder: /orders
        return []
    }
}
