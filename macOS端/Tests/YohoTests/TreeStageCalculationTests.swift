import Foundation
import Testing
@testable import Yoho

@Suite("Tree 阶段计算")
struct TreeStageCalculationTests {

    @Test("新树：种子期，进度 0")
    func newTreeIsSeed() {
        let goal = Goal(
            id: "test",
            title: "测试目标",
            targetDate: Date().addingTimeInterval(86400 * 30),
            createdAt: Date()
        )
        let tree = Tree(
            id: "test",
            stage: .seed,
            fertilizerCount: 0,
            targetFertilizerCount: 120,
            goal: goal,
            plantedAt: Date()
        )
        #expect(tree.stage == TreeStage.seed)
        #expect(tree.stageProgress == 0)
    }

    @Test("进度 20% 应为萌芽期")
    func twentyPercentIsSprout() {
        let goal = Goal(
            id: "test",
            title: "测试",
            targetDate: Date().addingTimeInterval(86400 * 30),
            createdAt: Date()
        )
        let tree = Tree(
            id: "test",
            stage: .sprout,
            fertilizerCount: 24,
            targetFertilizerCount: 120,
            goal: goal,
            plantedAt: Date()
        )
        #expect(tree.stageProgress == 0.2)
        #expect(tree.stage == TreeStage.sprout)
    }

    @Test("进度 100% 为结果期")
    func fullProgressIsFruiting() {
        let goal = Goal(
            id: "test",
            title: "测试",
            targetDate: Date().addingTimeInterval(86400 * 30),
            createdAt: Date()
        )
        let tree = Tree(
            id: "test",
            stage: .fruiting,
            fertilizerCount: 120,
            targetFertilizerCount: 120,
            goal: goal,
            plantedAt: Date()
        )
        #expect(tree.stageProgress == 1.0)
    }

    @Test("余额天数 ≥ 0")
    func remainingDaysNonNegative() {
        // 边界：用固定过去日期验证不返回负数
        let goal = Goal(
            id: "test",
            title: "测试",
            targetDate: Date().addingTimeInterval(-86400),
            createdAt: Date()
        )
        #expect(goal.remainingDays >= 0)
    }

    @Test("未来 30 天余额接近 30")
    func remainingDaysApprox30() {
        let goal = Goal(
            id: "test",
            title: "测试",
            targetDate: Date().addingTimeInterval(86400 * 30 + 3600),
            createdAt: Date()
        )
        // 加 1 小时缓冲，避免跨日边界
        #expect(goal.remainingDays == 30)
    }

    @Test("TreeStore 种植和施肥")
    @MainActor
    func plantAndFertilize() {
        let store = TreeStore()
        let goal = Goal(
            id: "test",
            title: "测试",
            targetDate: Date().addingTimeInterval(86400 * 10),
            createdAt: Date()
        )
        store.plantTree(goal: goal)
        #expect(store.currentTree != nil)
        #expect(store.currentTree?.stage == TreeStage.seed)

        let applied = store.applyFertilizer()
        #expect(applied)
        #expect(store.currentTree?.fertilizerCount == 1)
    }

    @Test("TreeStore 封存")
    @MainActor
    func archiveTree() {
        let store = TreeStore()
        let goal = Goal(
            id: "test",
            title: "测试",
            targetDate: Date().addingTimeInterval(86400 * 10),
            createdAt: Date()
        )
        store.plantTree(goal: goal)
        store.archiveCurrentTree(reason: "测试封存")
        #expect(store.currentTree == nil)
        #expect(store.archivedTrees.count == 1)
        #expect(store.archivedTrees[0].archivedReason == "测试封存")
    }
}
