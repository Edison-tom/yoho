import SwiftUI

@MainActor
@Observable
final class PetStore {
    var pet = Pet(
        id: UUID().uuidString,
        breed: .silverShaded,
        state: .idle,
        name: "小银",
        role: .shared
    )
    var fertilizerCount = 0
    var pendingFertilizerCount = 0

    private var microTimer: Timer?
    private var hungryTimer: Timer?
    private var cookiesAvailable = 0
    private var cookieTimerCheck: (() -> Int)?

    /// 启动微动作定时器（30-60s 随机）
    func startMicroActions(cookieProvider: @escaping () -> Int) {
        cookieTimerCheck = cookieProvider
        scheduleNextMicro()
        startHungryCheck()
    }

    func stopMicroActions() {
        microTimer?.invalidate()
        microTimer = nil
        hungryTimer?.invalidate()
        hungryTimer = nil
    }

    private func scheduleNextMicro() {
        microTimer?.invalidate()
        let interval = TimeInterval.random(in: 30...60)
        microTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.playRandomMicro()
            }
        }
    }

    private func startHungryCheck() {
        hungryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkHungry()
            }
        }
    }

    private func checkHungry() {
        guard pet.state == .idle else { return }
        let cookies = cookieTimerCheck?() ?? 0
        if cookies > 0 {
            pet.state = .hungry
            Task {
                try? await Task.sleep(for: .seconds(3))
                if pet.state == .hungry {
                    pet.state = .idle
                }
            }
        }
    }

    private func playRandomMicro() {
        guard pet.state == .idle else {
            scheduleNextMicro()
            return
        }
        let idx = Int.random(in: 1...6)
        pet.state = .micro(idx)
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            if case .micro = pet.state {
                pet.state = .idle
            }
            scheduleNextMicro()
        }
    }

    /// 喂食（拖拽饼干到宠物）
    func feed() {
        guard pet.state == .idle || pet.state == .hungry else { return }

        pet.state = .eating
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            pet.state = .producing
            try? await Task.sleep(for: .seconds(2.0))
            produceFertilizer()
        }
    }

    private func produceFertilizer() {
        guard fertilizerCount < Constants.maxFertilizerOnDesktop else {
            pet.state = .runningOut
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                if pet.state == .runningOut {
                    pet.state = .idle
                }
            }
            return
        }
        fertilizerCount += 1
        pendingFertilizerCount += 1
        pet.state = .idle
    }

    /// 摸摸头
    func petPet() {
        guard pet.state == .idle else { return }
        pet.state = .petting
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if pet.state == .petting {
                pet.state = .idle
            }
        }
    }

    /// 睡觉（长时间无操作）
    func goToSleep() {
        guard pet.state == .idle else { return }
        pet.state = .sleeping
    }

    /// 起床
    func wakeUp() {
        guard pet.state == .sleeping else { return }
        pet.state = .wakingUp
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if pet.state == .wakingUp {
                pet.state = .idle
            }
        }
    }

    /// 树阶段跃迁
    func celebrateStageUp() {
        pet.state = .stageUp
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if pet.state == .stageUp {
                pet.state = .idle
            }
        }
    }

    /// 结果期庆祝
    func celebrateFruiting() {
        pet.state = .celebrating
    }

    /// 串门到达（随机串门或手动触发）
    func visitingArrive(fromUserId: String? = nil) {
        pet.role = .visiting
        pet.visitingFromUserId = fromUserId
        pet.state = .visiting
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.0))
            if pet.state == .visiting {
                pet.state = .idle
            }
        }
    }

    /// 串门宠物回家
    func visitingReturn() {
        pet.role = .personal
        pet.visitingFromUserId = nil
        pet.state = .idle
    }

    func convertToPersonalPet() {
        pet.role = .personal
        pet.visitingFromUserId = nil
    }
}
