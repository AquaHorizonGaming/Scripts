import SwiftUI

struct ProductListView: View {
    @EnvironmentObject var viewModel: ProductListViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var selectedCategory: Category?

    var body: some View {
        NavigationView {
            List {
                if !viewModel.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.categories) { category in
                                Button(action: {
                                    selectedCategory = category
                                    Task { await viewModel.loadProducts(for: category) }
                                }) {
                                    VStack {
                                        if let url = category.imageURL {
                                            AsyncImage(url: url) { image in
                                                image.resizable()
                                            } placeholder: { Color.gray }
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                        }
                                        Text(category.name)
                                    }
                                }
                            }
                        }
                    }
                }
                ForEach(viewModel.products) { product in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.headline)
                            Text(product.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("$\(product.price, specifier: "%.2f")")
                                .font(.subheadline)
                        }
                        Spacer()
                        Button(action: { cartViewModel.add(product: product) }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .task {
                await viewModel.loadCategories()
                await viewModel.loadProducts(for: selectedCategory)
            }
            .navigationTitle("Products")
        }
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView()
            .environmentObject(ProductListViewModel())
            .environmentObject(CartViewModel())
    }
}
