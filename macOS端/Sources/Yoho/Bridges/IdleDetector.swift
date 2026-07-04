import CoreGraphics

final class IdleDetector {
    /// 上次键鼠事件至今的秒数
    static func secondsSinceLastInput() -> Double {
        let anyEvent = CGEventType(rawValue: ~0) ?? .null
        return CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: anyEvent
        )
    }

    /// 用户是否活跃（键鼠空闲 < 5 分钟）
    static var isUserActive: Bool {
        secondsSinceLastInput() < Constants.idleThresholdSeconds
    }
}
