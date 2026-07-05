import Foundation

struct Goal: Identifiable, Codable {
    let id: String
    var title: String
    var goalType: GoalType
    var targetDate: Date
    var targetAmount: Double?     // 辅助计量：目标值（如50000元）
    var targetUnit: String?       // 辅助单位：元/次/小时
    var createdAt: Date

    enum GoalType: String, Codable, CaseIterable {
        case exam = "考研"
        case travel = "旅行"
        case car = "买车"
        case fitness = "健身"
        case custom = "自定义"

        var label: String { rawValue }
    }

    /// 剩余天数
    var remainingDays: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        return max(days, 0)
    }
}
