import Foundation

@MainActor
@Observable
final class FocusTimer {
    private(set) var todayMinutes = 0
    private(set) var cookies = 0
    private var accumulatedSeconds: TimeInterval = 0
    private var timer: Timer?
    private var lastResetDate: Date?
    private var isFirstDay = true

    private let dailyMaxCookies = Constants.dailyMaxCookies
    private let focusInterval = Constants.focusIntervalSeconds

    var isRunning: Bool { timer?.isValid ?? false }

    func start() {
        checkDayReset()
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(
            withTimeInterval: Constants.timerTickSeconds,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func tick() {
        checkDayReset()
        guard IdleDetector.isUserActive else { return }

        accumulatedSeconds += Constants.timerTickSeconds

        if accumulatedSeconds >= focusInterval {
            accumulatedSeconds = 0
            if isFirstDay || cookies < dailyMaxCookies {
                cookies += 1
                todayMinutes += 30
            }
        }
    }

    func consumeCookie() {
        guard cookies > 0 else { return }
        cookies -= 1
    }

    func simulateDayChange() {
        isFirstDay = false
        lastResetDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(-86400)
    }

    private func checkDayReset() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastResetDate,
           Calendar.current.startOfDay(for: last) != today {
            cookies = 0
            todayMinutes = 0
            accumulatedSeconds = 0
            isFirstDay = false
        }
        lastResetDate = today
    }
}
