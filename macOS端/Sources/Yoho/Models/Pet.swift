import Foundation

struct Pet: Identifiable, Codable {
    let id: String
    var breed: PetBreed
    var state: PetState
    var name: String
    var role: Role
    var visitingFromUserId: String? = nil   // 串门来源用户 ID（仅 visiting 角色有效）

    enum Role: String, Codable {
        case shared
        case personal
        case visiting                     // 串门中（来自其他成员）
    }
}

enum PetBreed: String, Codable, CaseIterable {
    case silverShaded = "银渐层"      // 英短银渐层 — 温顺、安静、圆脸绿眼
    case ragdoll = "布偶"             // 布偶猫 — 温柔、黏人、蓝眼长毛
    case poodle = "泰迪"              // 泰迪犬 — 活泼、聪明、卷毛小型
    case goldenRetriever = "金毛"     // 金毛寻回犬 — 忠诚、温柔、大型犬

    var animationPrefix: String {
        switch self {
        case .silverShaded: return "silverShaded"
        case .ragdoll: return "ragdoll"
        case .poodle: return "poodle"
        case .goldenRetriever: return "goldenRetriever"
        }
    }
}

enum PetState: Equatable {
    case idle
    case micro(Int)
    case petting
    case eating
    case producing
    case sleeping
    case wakingUp
    case runningOut
    case visiting
    case stageUp
    case celebrating
    case hungry

    var label: String {
        switch self {
        case .idle: return ""
        case .micro: return ""
        case .petting: return "开心~"
        case .eating: return "好吃!"
        case .producing: return "产出中..."
        case .sleeping: return "Zzz"
        case .wakingUp: return "早安~"
        case .runningOut: return "该施肥啦!"
        case .visiting: return "串门中..."
        case .stageUp: return "长大啦!"
        case .celebrating: return "🎉"
        case .hungry: return "饿了..."
        }
    }

    var rawValue: String {
        switch self {
        case .idle: return "idle"
        case .micro(let i): return "micro_\(i)"
        case .petting: return "petting"
        case .eating: return "eating"
        case .producing: return "producing"
        case .sleeping: return "sleeping"
        case .wakingUp: return "wakingUp"
        case .runningOut: return "runningOut"
        case .visiting: return "visiting"
        case .stageUp: return "stageUp"
        case .celebrating: return "celebrating"
        case .hungry: return "hungry"
        }
    }

    init(rawValue: String) {
        switch rawValue {
        case "idle": self = .idle
        case "petting": self = .petting
        case "eating": self = .eating
        case "producing": self = .producing
        case "sleeping": self = .sleeping
        case "wakingUp": self = .wakingUp
        case "runningOut": self = .runningOut
        case "visiting": self = .visiting
        case "stageUp": self = .stageUp
        case "celebrating": self = .celebrating
        case "hungry": self = .hungry
        default:
            if rawValue.hasPrefix("micro_"), let i = Int(rawValue.dropFirst(6)) {
                self = .micro(i)
            } else {
                self = .idle
            }
        }
    }
}

extension PetState: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(rawValue: value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
