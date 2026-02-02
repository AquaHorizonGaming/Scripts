import Foundation

struct Product: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let imageURL: URL?
    let price: Double
    let categoryID: Int
}
