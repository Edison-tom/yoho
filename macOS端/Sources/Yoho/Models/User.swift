import Foundation

/// 用户模型 — 对应 Supabase users 表
/// 关系模式由 couples/teams 表推导，不再使用 mode 枚举
struct User: Identifiable, Codable {
    let id: String
    var username: String
    var petBreed: PetBreed
    var nickname: String        // 默认「主人」
    var createdAt: Date

    /// 当前活跃的关系（本地推导，不从服务端下发 mode）
    var activeRelationships: [RelationshipType] = []

    enum RelationshipType: String, Codable, CaseIterable {
        case single = "单身"
        case couple = "情侣"
        case buddy  = "老铁"
        case sis    = "闺蜜"
    }
}
