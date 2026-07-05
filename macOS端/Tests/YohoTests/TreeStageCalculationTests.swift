import Foundation
import Testing
@testable import Yoho

@Suite("Tree 阶段计算")
struct TreeStageCalculationTests {

    func makeGoal(daysFromNow: Int = 30) -> Goal {
        Goal(
            id: UUID().uuidString,
            title: "测试目标",
            goalType: .custom,
            targetDate: Date().addingTimeInterval(86400 * Double(daysFromNow)),
            targetAmount: nil,
            targetUnit: nil,
            createdAt: Date()
        )
    }

    func makeTree(fertilizer: Int, target: Int, stage: TreeStage = .seed) -> Tree {
        let goal = makeGoal(daysFromNow: max(target / 4, 1))
        return Tree(
            id: UUID().uuidString,
            name: "测试树",
            stage: stage,
            fertilizerCount: fertilizer,
            targetFertilizerCount: target,
            goal: goal,
            relationshipType: .personal,
            coupleId: nil,
            teamId: nil,
            plantedAt: Date(),
            completedAt: nil,
            archivedAt: nil,
            archivedReason: nil
        )
    }

    @Test("新树：种子期，进度 0")
    func newTreeIsSeed() {
        let tree = makeTree(fertilizer: 0, target: 120)
        #expect(tree.stage == TreeStage.seed)
        #expect(tree.stageProgress == 0)
    }

    @Test("进度 20% 应为萌芽期")
    func twentyPercentIsSprout() {
        let tree = makeTree(fertilizer: 24, target: 120, stage: .sprout)
        #expect(tree.stageProgress == 0.2)
        #expect(tree.stage == TreeStage.sprout)
    }

    @Test("进度 100% 为结果期")
    func fullProgressIsFruiting() {
        let tree = makeTree(fertilizer: 120, target: 120, stage: .fruiting)
        #expect(tree.stageProgress == 1.0)
    }

    @Test("余额天数 ≥ 0")
    func remainingDaysNonNegative() {
        let goal = Goal(
            id: UUID().uuidString,
            title: "测试",
            goalType: .custom,
            targetDate: Date().addingTimeInterval(-86400),
            targetAmount: nil,
            targetUnit: nil,
            createdAt: Date()
        )
        #expect(goal.remainingDays >= 0)
    }

    @Test("未来 30 天余额接近 30")
    func remainingDaysApprox30() {
        let goal = Goal(
            id: UUID().uuidString,
            title: "测试",
            goalType: .custom,
            targetDate: Date().addingTimeInterval(86400 * 30 + 3600),
            targetAmount: nil,
            targetUnit: nil,
            createdAt: Date()
        )
        #expect(goal.remainingDays == 30)
    }

    @Test("TreeStore 种植和施肥")
    @MainActor
    func plantAndFertilize() {
        let store = TreeStore()
        let goal = makeGoal(daysFromNow: 10)
        store.plantTree(name: "测试树", goal: goal, relationshipType: .personal)
        #expect(store.activeTree != nil)
        #expect(store.activeTree?.stage == TreeStage.seed)

        let applied = store.applyFertilizer()
        #expect(applied)
        #expect(store.activeTree?.fertilizerCount == 1)
    }

    @Test("TreeStore 封存")
    @MainActor
    func archiveTree() {
        let store = TreeStore()
        let goal = makeGoal(daysFromNow: 10)
        store.plantTree(name: "测试树", goal: goal, relationshipType: .personal)
        store.archiveCurrentTree(reason: "测试封存")
        #expect(store.activeTree == nil)
        #expect(store.archivedTrees.count == 1)
        #expect(store.archivedTrees[0].archivedReason == "测试封存")
    }
}
