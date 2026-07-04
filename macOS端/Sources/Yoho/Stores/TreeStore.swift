import Foundation

@Observable
final class TreeStore {
    var currentTree: Tree?
    var archivedTrees: [Tree] = []

    /// 种植新树
    func plantTree(goal: Goal) {
        let remainingDays = goal.remainingDays
        let targetFertilizer = remainingDays * 4  // 每天 4 颗

        currentTree = Tree(
            id: UUID().uuidString,
            stage: .seed,
            fertilizerCount: 0,
            targetFertilizerCount: targetFertilizer,
            goal: goal,
            plantedAt: Date()
        )
    }

    /// 施肥
    func applyFertilizer() -> Bool {
        guard var tree = currentTree,
              tree.stage != .fruiting else { return false }

        tree.fertilizerCount += 1
        updateStage(for: &tree)
        currentTree = tree
        return true
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
        guard var tree = currentTree else { return }
        tree.archivedAt = Date()
        tree.archivedReason = reason
        archivedTrees.append(tree)
        currentTree = nil
    }
}
