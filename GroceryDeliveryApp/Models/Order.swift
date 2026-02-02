import Foundation

struct Order: Identifiable, Codable {
    let id: Int
    let date: Date
    let items: [CartItem]
    let total: Double
}
