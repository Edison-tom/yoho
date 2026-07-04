import Foundation

struct User: Identifiable, Codable {
    let id: String
    var username: String
    var mode: Mode
    var createdAt: Date

    enum Mode: String, Codable {
        case single
        case couple
    }
}
