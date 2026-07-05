import Foundation

struct Team: Identifiable, Codable {
    let id: String
    var name: String
    var mode: TeamMode
    var memberIds: [String]
    var treeId: String?
    var createdAt: Date
    var inviteCode: String?

    enum TeamMode: String, Codable, CaseIterable {
        case buddy = "老铁"
        case sis = "闺蜜"

        var emoji: String {
            switch self {
            case .buddy: "👊"
            case .sis: "👯"
            }
        }

        var label: String { rawValue }
    }

    var memberCount: Int { memberIds.count }
    var maxMembers: Int { 5 }
    var canInvite: Bool { memberCount < maxMembers }

    /// 生成6位邀请码
    static func generateInviteCode() -> String {
        String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
    }
}
