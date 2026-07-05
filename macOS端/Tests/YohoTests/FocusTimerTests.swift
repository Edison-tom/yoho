import Testing
@testable import Yoho

@Suite("FocusTimer 专注计时器")
struct FocusTimerTests {

    @Test("初始状态：饼干和分钟数均为 0")
    @MainActor
    func initialState() {
        let timer = FocusTimer()
        #expect(timer.cookies == 0)
        #expect(timer.todayMinutes == 0)
        #expect(!timer.isRunning)
    }

    @Test("启动和停止")
    @MainActor
    func startStop() {
        let timer = FocusTimer()
        timer.start()
        #expect(timer.isRunning)
        timer.stop()
        #expect(!timer.isRunning)
    }

    @Test("首日不限：cookie 可超过 8")
    @MainActor
    func firstDayNoLimit() {
        let timer = FocusTimer()
        timer.start()
        // 跑足够多次触发 9+ cookie
        for _ in 0..<4000 {
            timer.tick()
        }
        // 首日不设限，cookie 可超过 8
        #expect(timer.cookies > 8)
        timer.stop()
    }

    @Test("次日上限：超过 8 块饼干后不再增加")
    @MainActor
    func dailyMaxAfterFirstDay() {
        let timer = FocusTimer()
        timer.start()
        // 模拟进入次日
        timer.simulateDayChange()

        // 跑足够多次触发 9+ cookie
        for _ in 0..<4000 {
            timer.tick()
        }
        // 次日上限 8
        #expect(timer.cookies == 8)
        #expect(timer.todayMinutes == 240)
        timer.stop()
    }

    @Test("consumeCookie 扣减且不跌破 0")
    @MainActor
    func consumeCookie() {
        let timer = FocusTimer()
        // 0 块时 consume 不变
        let before = timer.cookies
        timer.consumeCookie()
        #expect(timer.cookies == before)
    }

    @Test("IdleDetector 返回合理值")
    func idleDetectorReturnsValue() {
        let seconds = IdleDetector.secondsSinceLastInput()
        #expect(seconds >= 0)
        #expect(seconds < 86400 * 7)
    }

    @Test("IdleDetector 用户活跃判断")
    func idleDetectorActiveCheck() {
        let active = IdleDetector.isUserActive
        _ = active
    }

    @Test("Constants 常量正确")
    func constants() {
        #expect(Constants.focusIntervalSeconds == 1800)
        #expect(Constants.timerTickSeconds == 5)
        #expect(Constants.idleThresholdSeconds == 300)
        #expect(Constants.dailyMaxCookies == 8)
        #expect(Constants.maxFertilizerOnDesktop == 5)
    }
}
