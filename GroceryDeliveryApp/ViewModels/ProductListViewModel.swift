import Foundation

class ProductListViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var products: [Product] = []

    func loadCategories() async {
        do {
            let categories = try await APIService.shared.fetchCategories()
            DispatchQueue.main.async {
                self.categories = categories
            }
        } catch {
            print("Category fetch error: \(error)")
        }
    }

    func loadProducts(for category: Category?) async {
        do {
            let products = try await APIService.shared.fetchProducts(in: category?.id)
            DispatchQueue.main.async {
                self.products = products
            }
        } catch {
            print("Product fetch error: \(error)")
        }
    }
}
