import Foundation
import Testing
@testable import Yoho

@Suite("PetStore 宠物状态")
struct PetStoreTests {

    @Test("初始状态")
    @MainActor
    func initialState() {
        let store = PetStore()
        #expect(store.pet.breed == PetBreed.orangeCat)
        #expect(store.pet.state == PetState.idle)
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
        #expect(PetBreed.orangeCat.animationPrefix == "orange_cat")
        #expect(PetBreed.corgi.animationPrefix == "corgi")
    }

    @Test("宠物状态动画命名")
    func petStateAnimationName() {
        let name = PetState.eating.animationName(for: .orangeCat)
        #expect(name == "orange_cat_eating")
    }
}
