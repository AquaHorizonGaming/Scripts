import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @StateObject private var checkoutViewModel = CheckoutViewModel()

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(cartViewModel.items) { item in
                        HStack {
                            Text(item.product.name)
                            Spacer()
                            Stepper(value: Binding(
                                get: { item.quantity },
                                set: { cartViewModel.updateQuantity(for: item.product, quantity: $0) }
                            ), in: 1...20) {
                                Text("Qty: \(item.quantity)")
                            }
                        }
                    }
                    if cartViewModel.items.isEmpty {
                        Text("Your cart is empty")
                    }
                }
                VStack(spacing: 10) {
                    TextField("Delivery Address", text: $checkoutViewModel.address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    DatePicker("Delivery Time", selection: $checkoutViewModel.scheduledDate, displayedComponents: [.date, .hourAndMinute])
                    Text("Total: $\(cartViewModel.total, specifier: "%.2f")")
                        .font(.headline)
                    Button("Checkout") {
                        Task { await checkoutViewModel.checkout(cart: cartViewModel) }
                    }
                    .buttonStyle(.borderedProminent)
                    if checkoutViewModel.isProcessing {
                        ProgressView()
                    }
                }
                .padding()
            }
            .navigationTitle("Cart")
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
            .environmentObject(CartViewModel())
    }
}
