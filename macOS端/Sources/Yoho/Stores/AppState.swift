import SwiftUI

@MainActor
@Observable
final class AppState {
    /// 多关系并行：一个人可同时在 0-N 个关系中
    var activeRelationships: [User.RelationshipType] = [.single]
    var myNickname: String = "主人"
    
    /// 情侣模式专属
    var partnerNickname: String = "宝宝"
    var callPartnerAs: String = "宝宝"

    /// 我参与的队伍（老铁/闺蜜）
    var activeTeams: [TeamInfo] = []
    var teamIds: [String] { activeTeams.map(\.id) }

    var isFirstLaunch = true

    // 子系统
    var focusTimer = FocusTimer()
    var petStore = PetStore()
    var treeStore = TreeStore()

    /// 随机串门引擎（老铁/闺蜜模式）
    var randomVisitEngine = RandomVisitEngine()

    /// 是否处于情侣关系
    var isInCouple: Bool {
        activeRelationships.contains(.couple)
    }

    /// 是否有任何组队关系
    var hasTeams: Bool {
        !activeTeams.isEmpty
    }

    /// 当前是否有活跃的串门宠物
    var hasVisitingPet: Bool {
        randomVisitEngine.activeVisit != nil
    }
}

/// 队伍简要信息（本地缓存）
struct TeamInfo: Identifiable, Codable {
    let id: String
    var name: String?
    var mode: TeamMode
    var memberIds: [String]
    var treeId: String?

    enum TeamMode: String, Codable {
        case buddy = "老铁"
        case sis = "闺蜜"
    }
}
