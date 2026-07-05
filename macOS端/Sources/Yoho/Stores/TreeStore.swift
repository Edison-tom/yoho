import Foundation

@Observable
final class TreeStore {
    /// 最多显示 3 棵树（按截止日期紧迫度排序，用户可手动钉选）
    var visibleTrees: [Tree] = []
    /// 全部树（含不可见的）
    var allTrees: [Tree] = []
    var archivedTrees: [Tree] = []
    var onStageChanged: ((TreeStage, TreeStage) -> Void)?

    /// 当前激活的树（用户正在查看的那棵）
    var activeTree: Tree? { visibleTrees.first }

    var currentTree: Tree? { activeTree }

    func plantTree(
        name: String,
        goal: Goal,
        relationshipType: Tree.RelationshipType,
        coupleId: String? = nil,
        teamId: String? = nil
    ) {
        let remainingDays = goal.remainingDays
        let targetFertilizer = max(remainingDays * 4, 4)

        let tree = Tree(
            id: UUID().uuidString,
            name: name,
            stage: .seed,
            fertilizerCount: 0,
            targetFertilizerCount: targetFertilizer,
            goal: goal,
            relationshipType: relationshipType,
            coupleId: coupleId,
            teamId: teamId,
            plantedAt: Date(),
            completedAt: nil,
            archivedAt: nil,
            archivedReason: nil
        )
        allTrees.append(tree)
        if visibleTrees.count < 3 {
            visibleTrees.append(tree)
        }
    }

    func applyFertilizer(to treeId: String? = nil) -> Bool {
        let targetId = treeId ?? activeTree?.id
        guard let idx = allTrees.firstIndex(where: { $0.id == targetId }),
              allTrees[idx].stage != .fruiting else { return false }

        let oldStage = allTrees[idx].stage
        allTrees[idx].fertilizerCount += 1
        updateStage(for: &allTrees[idx])

        if allTrees[idx].stage != oldStage {
            onStageChanged?(oldStage, allTrees[idx].stage)
        }

        // 同步更新 visibleTrees 中的引用
        if let vIdx = visibleTrees.firstIndex(where: { $0.id == targetId }) {
            visibleTrees[vIdx] = allTrees[idx]
        }
        return true
    }

    func switchToTree(_ treeId: String) {
        guard let tree = allTrees.first(where: { $0.id == treeId }) else { return }
        // 将被选中的树移到 visibleTrees 首位
        visibleTrees.removeAll { $0.id == treeId }
        visibleTrees.insert(tree, at: 0)
    }

    func pinTree(_ treeId: String) {
        // 钉选：该树始终显示在前 3 棵
        guard let tree = allTrees.first(where: { $0.id == treeId }) else { return }
        visibleTrees.removeAll { $0.id == treeId }
        visibleTrees.insert(tree, at: 0)
        // 保持最多 3 棵
        if visibleTrees.count > 3 {
            visibleTrees = Array(visibleTrees.prefix(3))
        }
    }

    private func updateStage(for tree: inout Tree) {
        let progress = tree.stageProgress
        for stage in TreeStage.allCases.reversed() {
            if progress >= stage.progressThreshold {
                tree.stage = stage
                break
            }
        }
    }

    func archiveCurrentTree(reason: String) {
        guard var tree = activeTree else { return }
        tree.archivedAt = Date()
        tree.archivedReason = reason
        archivedTrees.append(tree)
        allTrees.removeAll { $0.id == tree.id }
        visibleTrees.removeAll { $0.id == tree.id }
    }
}
