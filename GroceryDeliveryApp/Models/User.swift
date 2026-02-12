import Foundation

struct User: Identifiable, Codable {
    let id: Int
    let name: String
    let email: String
    let token: String?
}
