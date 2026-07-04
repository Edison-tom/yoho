import Foundation

enum Constants {
    /// 窗口默认尺寸
    static let windowWidth: CGFloat = 240
    static let windowHeight: CGFloat = 320
    static let windowMinWidth: CGFloat = 200
    static let windowMinHeight: CGFloat = 280

    /// 半透明 alpha 值
    static let idleAlpha: CGFloat = 0.8
    static let hoverAlpha: CGFloat = 1.0

    /// 专注计时
    static let focusIntervalSeconds: TimeInterval = 30 * 60
    static let timerTickSeconds: TimeInterval = 5
    static let idleThresholdSeconds: Double = 300
    static let dailyMaxCookies = 8

    /// 肥料
    static let maxFertilizerOnDesktop = 5

    /// 宠物
    static let petSize: CGFloat = 60

    /// 动画时长
    static let alphaTransitionDuration: TimeInterval = 0.3
    static let treeStageTransitionDuration: TimeInterval = 0.8
}
