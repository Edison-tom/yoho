import Foundation

/// 树动画配置
struct TreeAnimation: Sendable {
    let fileName: String
    let isLooping: Bool
    let duration: TimeInterval

    static func stage(_ stage: TreeStage) -> TreeAnimation {
        let name = "tree_stage_\(stage.rawValue)"
        switch stage {
        case .seed:
            return TreeAnimation(fileName: name, isLooping: true, duration: 0)
        case .sprout, .growing, .lush:
            return TreeAnimation(fileName: name, isLooping: true, duration: 0)
        case .blooming:
            return TreeAnimation(fileName: name, isLooping: true, duration: 0)
        case .fruiting:
            return TreeAnimation(fileName: name, isLooping: true, duration: 0)
        }
    }

    static func transition(from oldStage: TreeStage, to newStage: TreeStage) -> TreeAnimation {
        let name = "tree_transition_\(oldStage.rawValue)_to_\(newStage.rawValue)"
        return TreeAnimation(fileName: name, isLooping: false, duration: 1.5)
    }

    var mp4Exists: Bool {
        Bundle.main.url(forResource: fileName, withExtension: "mp4") != nil
    }
}
