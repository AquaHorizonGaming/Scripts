import SwiftUI

struct OrderHistoryView: View {
    @EnvironmentObject var viewModel: OrderHistoryViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.orders) { order in
                    VStack(alignment: .leading) {
                        Text(order.date, style: .date)
                            .font(.headline)
                        Text("Items: \(order.items.count) | Total: $\(order.total, specifier: "%.2f")")
                        Button("Reorder") {
                            // Placeholder for reorder action
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .task { await viewModel.loadHistory() }
            .navigationTitle("Order History")
        }
    }
}

struct OrderHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        OrderHistoryView()
            .environmentObject(OrderHistoryViewModel())
    }
}
