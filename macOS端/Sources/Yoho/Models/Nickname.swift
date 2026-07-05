import Foundation

/// 昵称模型 — 按关系类型分别存储
struct Nickname: Codable {
    /// 我的昵称（所有模式共用，默认「主人」）
    var myName: String = "主人"

    /// 情侣模式：我称呼伴侣的方式（默认「宝宝」）
    var callPartnerAs: String = "宝宝"

    /// 情侣模式：伴侣的昵称（从服务端同步）
    var partnerName: String = "宝宝"

    /// 老铁模式：我的昵称（默认「兄弟」）
    var buddyName: String = "兄弟"

    /// 闺蜜模式：我的昵称（默认「姐妹」）
    var sisName: String = "姐妹"

    /// 根据关系类型取对应的昵称
    func myName(for relationship: User.RelationshipType) -> String {
        switch relationship {
        case .single: return myName
        case .couple: return myName
        case .buddy:  return buddyName
        case .sis:    return sisName
        }
    }

    /// 验证昵称合法性
    static func isValid(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        // 2-8 个中文或 4-16 个英文
        let chineseCount = trimmed.unicodeScalars.filter { $0 >= "\u{4E00}" && $0 <= "\u{9FFF}" }.count
        let otherCount = trimmed.count - chineseCount
        if chineseCount > 0 {
            return chineseCount >= 2 && chineseCount <= 8
        }
        return otherCount >= 4 && otherCount <= 16
    }
}
