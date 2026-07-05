import Foundation
import Testing
@testable import Yoho

@Suite("PetStore 宠物状态")
struct PetStoreTests {

    @Test("初始状态")
    @MainActor
    func initialState() {
        let store = PetStore()
        #expect(store.pet.breed == PetBreed.silverShaded)
        #expect(store.pet.state == .idle)
        #expect(store.fertilizerCount == 0)
    }

    @Test("转为专属宠物")
    @MainActor
    func convertToPersonal() {
        let store = PetStore()
        store.convertToPersonalPet()
        #expect(store.pet.role == Pet.Role.personal)
    }

    @Test("宠物品种枚举")
    func petBreeds() {
        #expect(PetBreed.allCases.count == 4)
    }

    @Test("PetState Codable 往返")
    func stateCodable() throws {
        let states: [PetState] = [
            .idle, .eating, .producing, .sleeping, .wakingUp,
            .runningOut, .visiting, .stageUp, .celebrating, .hungry,
            .micro(3), .petting
        ]
        for state in states {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(PetState.self, from: data)
            #expect(decoded == state)
        }
    }

    @Test("PetState label")
    func stateLabels() {
        #expect(PetState.idle.label == "")
        #expect(PetState.eating.label == "好吃!")
        #expect(PetState.sleeping.label == "Zzz")
        #expect(PetState.hungry.label == "饿了...")
        #expect(PetState.celebrating.label == "🎉")
    }

    @Test("PetAnimation 文件命名")
    func animationFileName() {
        let anim = PetAnimation.idle(for: .silverShaded)
        #expect(anim.fileName == "silverShaded_idle")
        #expect(anim.isLooping)

        let micro = PetAnimation.micro(for: .poodle, index: 3)
        #expect(micro.fileName == "poodle_micro_03")
        #expect(!micro.isLooping)
    }
}
