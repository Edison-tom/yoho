import SwiftUI

@MainActor
@Observable
final class PetStore {
    var pet = Pet(
        id: UUID().uuidString,
        breed: .orangeCat,
        state: .idle,
        name: "小橘",
        role: .shared
    )
    var fertilizerCount = 0
    var pendingFertilizerCount = 0

    /// 喂食：消耗饼干 → 3-5 分钟后产出肥料
    func feed(cookieCount: inout Int) {
        guard cookieCount > 0 else { return }
        cookieCount -= 1
        pet.state = .eating

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            pet.state = .idle

            // 模拟排泄延迟
            try? await Task.sleep(for: .seconds(3 * 60))
            produceFertilizer()
        }
    }

    private func produceFertilizer() {
        let maxOnDesktop = Constants.maxFertilizerOnDesktop
        guard fertilizerCount < maxOnDesktop else {
            pet.state = .runningOut
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                pet.state = .idle
            }
            return
        }
        pet.state = .producing
        fertilizerCount += 1
        pendingFertilizerCount += 1
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            pet.state = .idle
        }
    }

    func convertToPersonalPet() {
        pet.role = .personal
    }
}
