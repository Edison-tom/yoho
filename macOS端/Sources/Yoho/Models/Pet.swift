import Foundation

struct Pet: Identifiable, Codable {
    let id: String
    var breed: PetBreed
    var state: PetState
    var name: String
    var role: Role

    enum Role: String, Codable {
        case shared    // 共养宠物
        case personal  // 专属宠物
    }
}

enum PetBreed: String, Codable, CaseIterable {
    case orangeCat = "橘猫"
    case calicoCat = "狸花"
    case corgi = "柯基"
    case goldenRetriever = "金毛"

    var animationPrefix: String {
        switch self {
        case .orangeCat: return "orange_cat"
        case .calicoCat: return "calico"
        case .corgi: return "corgi"
        case .goldenRetriever: return "golden"
        }
    }
}

enum PetState: String, Codable {
    case idle
    case eating
    case producing
    case sleeping
    case runningOut
    case visiting

    var isLooping: Bool {
        switch self {
        case .idle, .sleeping: return true
        case .eating, .producing, .runningOut, .visiting: return false
        }
    }

    func animationName(for breed: PetBreed) -> String {
        "\(breed.animationPrefix)_\(rawValue)"
    }
}
