import Foundation

/// 随机串门引擎 — 产品方案 §4.5.3/§4.6.3
/// 全自动触发，无需用户手动操作
@MainActor
@Observable
final class RandomVisitEngine {
    /// 当前活跃的到访宠物（同一时间只显示 1 只串门宠物）
    private(set) var activeVisit: PetVisit?

    /// 今日已串门记录：petId → 次数
    private var dailyCounts: [String: Int] = [:]

    /// 上次串门时间（冷却用）
    private var lastVisitTime: Date?
    private var checkTimer: Timer?

    /// 冷却时长（2 小时）
    private let cooldownInterval: TimeInterval = 2 * 3600
    /// 每日最大串门次数（每只宠物）
    private let maxDailyVisits = 3
    /// 检查间隔
    private let checkInterval: TimeInterval = 30 * 60
    /// 触发概率
    private let triggerProbability = 0.30

    /// 外部依赖注入
    var onlineMemberCount: () -> Int = { 0 }
    var activeMemberIds: () -> [String] = { [] }
    var pickRandomPetFromMember: (String) -> (petId: String, breed: PetBreed, name: String)? = { _ in nil }
    var onVisitStart: ((PetVisit) -> Void)?
    var onVisitEnd: ((PetVisit) -> Void)?

    // MARK: - 生命周期

    func start() {
        stop()
        scheduleNextCheck()
    }

    func stop() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    func resetDailyCounts() {
        dailyCounts = [:]
    }

    // MARK: - 核心逻辑

    private func scheduleNextCheck() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateTrigger()
            }
        }
    }

    /// 评估是否触发随机串门
    func evaluateTrigger() -> Bool {
        // 1. 检查是否已有活跃串门
        guard activeVisit == nil else { return false }

        // 2. 冷却检查
        if let last = lastVisitTime,
           Date().timeIntervalSince(last) < cooldownInterval {
            return false
        }

        // 3. 至少 2 人在线活跃
        let members = activeMemberIds()
        let online = onlineMemberCount()
        guard online >= 2, members.count >= 2 else { return false }

        // 4. 随机概率 (~30%)
        guard Double.random(in: 0...1) < triggerProbability else { return false }

        // 5. 随机选中发起人和接收人
        guard let (ownerId, targetId) = pickRandomPair(from: members) else { return false }

        // 6. 选中的宠物当天串门次数 < 3
        guard let pet = pickRandomPetFromMember(ownerId) else { return false }
        let count = dailyCounts[pet.petId] ?? 0
        guard count < maxDailyVisits else { return false }

        // 7. 创建串门记录
        let stayMinutes = TimeInterval(Int.random(in: 10...30))
        let visit = PetVisit(
            id: UUID().uuidString,
            petId: pet.petId,
            fromUserId: ownerId,
            toUserId: targetId,
            teamId: "",
            petBreed: pet.breed,
            ownerName: pet.name,
            arrivedAt: Date(),
            expiresAt: Date().addingTimeInterval(stayMinutes * 60),
            dailyVisitCount: count + 1
        )

        dailyCounts[pet.petId] = count + 1
        lastVisitTime = Date()

        // 8. 显示到访动画
        activeVisit = visit
        onVisitStart?(visit)

        // 9. 设定自动回家定时器
        scheduleReturn(for: visit)

        return true
    }

    /// 当前活跃的到访宠物（供 View 层读取）
    var visitingPet: PetVisit? { activeVisit }

    /// 手动结束当前串门（自动回家时调用）
    func endCurrentVisit() {
        guard let visit = activeVisit else { return }
        activeVisit = nil
        onVisitEnd?(visit)
    }

    // MARK: - 私有方法

    private func pickRandomPair(from members: [String]) -> (String, String)? {
        guard members.count >= 2 else { return nil }
        let shuffled = members.shuffled()
        return (shuffled[0], shuffled[1])
    }

    private func scheduleReturn(for visit: PetVisit) {
        let delay = visit.remainingSeconds
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            if activeVisit?.id == visit.id {
                endCurrentVisit()
            }
        }
    }
}
