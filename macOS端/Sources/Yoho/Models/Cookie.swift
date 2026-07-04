import Foundation

struct Cookie: Identifiable, Codable {
    let id: String
    var count: Int
    var todayCount: Int
    var lastResetDate: Date
}
