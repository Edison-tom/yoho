import Foundation

/// 宠物串门记录 — 对应 Supabase pet_visits 表
struct PetVisit: Identifiable, Codable {
    let id: String
    let petId: String
    let fromUserId: String
    let toUserId: String
    let teamId: String
    let petBreed: PetBreed
    let ownerName: String             // 宠物主人昵称
    let arrivedAt: Date
    let expiresAt: Date               // 10-30 分钟后自动回家
    var dailyVisitCount: Int = 1
    let isRandom: Bool = true         // 标记为随机串门

    /// 剩余停留秒数
    var remainingSeconds: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }

    /// 是否已过期（该回家了）
    var isExpired: Bool {
        Date() >= expiresAt
    }
}
