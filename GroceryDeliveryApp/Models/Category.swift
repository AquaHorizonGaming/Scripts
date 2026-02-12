import Foundation

struct Category: Identifiable, Codable {
    let id: Int
    let name: String
    let imageURL: URL?
}
