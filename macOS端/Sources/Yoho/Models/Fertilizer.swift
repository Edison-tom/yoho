import Foundation

struct Fertilizer: Identifiable, Codable {
    let id: String
    var count: Int
    var pendingCount: Int  // 已产出待投喂
}
