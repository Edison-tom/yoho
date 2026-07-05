import Foundation

/// 宠物动画配置
struct PetAnimation: Sendable {
    let fileName: String
    let isLooping: Bool
    let duration: TimeInterval

    static func idle(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_idle", isLooping: true, duration: 0)
    }

    static func micro(for breed: PetBreed, index: Int) -> PetAnimation {
        let i = String(format: "%02d", index)
        return PetAnimation(fileName: "\(breed.animationPrefix)_micro_\(i)", isLooping: false, duration: 1.5)
    }

    static func petting(for breed: PetBreed, variant: Int) -> PetAnimation {
        let v = String(format: "%02d", variant)
        return PetAnimation(fileName: "\(breed.animationPrefix)_petting_\(v)", isLooping: false, duration: 2.0 + Double(variant) * 0.5)
    }

    static func eating(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_eating", isLooping: false, duration: 2.5)
    }

    static func producing(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_producing", isLooping: false, duration: 2.0)
    }

    static func sleeping(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_sleeping", isLooping: false, duration: 2.0)
    }

    static func sleepingLoop(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_sleeping_loop", isLooping: true, duration: 0)
    }

    static func wakingUp(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_wakingUp", isLooping: false, duration: 1.5)
    }

    static func reminder(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_reminder", isLooping: false, duration: 2.0)
    }

    static func visitingLeave(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_visiting_leave", isLooping: false, duration: 1.5)
    }

    static func visitingArrive(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_visiting_arrive", isLooping: false, duration: 1.5)
    }

    static func stageUp(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_stageUp", isLooping: false, duration: 2.0)
    }

    static func celebrating(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_celebrating", isLooping: true, duration: 2.0)
    }

    static func hungry(for breed: PetBreed) -> PetAnimation {
        PetAnimation(fileName: "\(breed.animationPrefix)_hungry", isLooping: false, duration: 2.0)
    }

    /// 检查 bundle 中是否存在对应 MP4
    var mp4Exists: Bool {
        guard Bundle.main.url(forResource: fileName, withExtension: "mp4") != nil else {
            return false
        }
        return true
    }
}
