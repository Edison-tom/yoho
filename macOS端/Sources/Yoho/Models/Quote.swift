import Foundation

struct Quote: Identifiable, Codable {
    let id: String
    let text: String
    let scene: Scene

    enum Scene: String, Codable {
        case focusComplete  // 完成专注
        case treeStageUp    // 树阶段提升
        case coupleSync     // 情侣同步
        case idle           // 空闲随机
    }
}
