import Foundation

/// 树模型 — 对应 Supabase user_trees 表
struct Tree: Identifiable, Codable {
    let id: String
    var name: String                           // 树名（如"北大上岸树"）
    var stage: TreeStage
    var fertilizerCount: Int
    var targetFertilizerCount: Int
    var goal: Goal
    var relationshipType: RelationshipType     // 这棵树属于哪种关系
    var coupleId: String?                      // 情侣 ID（情侣树）
    var teamId: String?                        // 队伍 ID（老铁/闺蜜树）
    var plantedAt: Date
    var completedAt: Date?                     // 达成时间
    var archivedAt: Date?
    var archivedReason: String?

    enum RelationshipType: String, Codable {
        case personal = "个人"
        case couple = "情侣"
        case buddy = "老铁"
        case sis = "闺蜜"
    }

    /// 阶段进度 0.0–1.0
    var stageProgress: Double {
        guard targetFertilizerCount > 0 else { return 0 }
        let progress = Double(fertilizerCount) / Double(targetFertilizerCount)
        return min(max(progress, 0), 1)
    }
}

enum TreeStage: Int, Codable, CaseIterable {
    case seed = 0      // 种子期 0%
    case sprout = 1    // 萌芽期 20%
    case growing = 2   // 成长期 40%
    case lush = 3      // 繁茂期 60%
    case blooming = 4  // 开花期 80%
    case fruiting = 5  // 结果期 100%

    var progressThreshold: Double {
        Double(rawValue) / Double(TreeStage.allCases.count - 1)
    }

    var imageName: String {
        "tree_\(rawValue)"
    }

    var label: String {
        switch self {
        case .seed: return "🌰 种子期"
        case .sprout: return "🌱 萌芽期"
        case .growing: return "🌿 成长期"
        case .lush: return "🌳 繁茂期"
        case .blooming: return "🌸 开花期"
        case .fruiting: return "🍇 结果期"
        }
    }
}
