import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingWindow: NSWindow?
    private var mouseTracker: MouseTracker?
    let appState = AppState()

    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            NSApp.setActivationPolicy(.accessory)
            setupAppIcon()
            NSApp.mainMenu?.item(withTag: 0)?.submenu?.item(withTag: 0)?.title = "Yoho"
            wireCallbacks()
            createFloatingWindow()
            appState.focusTimer.start()
            appState.petStore.startMicroActions { [weak self] in
                self?.appState.focusTimer.cookies ?? 0
            }
            plantDemoTree()
        }
    }

    private func plantDemoTree() {
        let goal = Goal(
            id: UUID().uuidString,
            title: "专注每一天",
            goalType: .custom,
            targetDate: Date().addingTimeInterval(86400 * 30),
            targetAmount: nil, targetUnit: nil, createdAt: Date()
        )
        appState.treeStore.plantTree(
            name: "成长树",
            goal: goal,
            relationshipType: .personal
        )
    }

    nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker?.stop()
        appState.focusTimer.stop()
        appState.petStore.stopMicroActions()
    }

    private func wireCallbacks() {
        // 树阶段跃迁 → 宠物庆祝 + 金句
        appState.treeStore.onStageChanged = { [weak self] oldStage, newStage in
            guard let self else { return }
            if newStage == .fruiting {
                self.appState.petStore.celebrateFruiting()
                self.appState.showQuote(forScene: .tree_stage)
            } else {
                self.appState.petStore.celebrateStageUp()
                self.appState.showQuote(forScene: .tree_stage)
            }
        }
    }

    private func setupAppIcon() {
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "icns", subdirectory: "Resources"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = iconImage
        }
    }

    private func createFloatingWindow() {
        let contentView = ContentView()
            .environment(appState)
        let hostingView = NSHostingView(rootView: contentView)

        let window = FloatingWindow(
            contentRect: NSRect(x: 0, y: 0, width: Constants.windowWidth, height: Constants.windowHeight)
        )
        window.contentView = hostingView

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - Constants.windowWidth - 20
            let y = screenFrame.minY + 20
            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
        self.floatingWindow = window

        mouseTracker = MouseTracker(window: window)
        mouseTracker?.start()

        NSApp.activate(ignoringOtherApps: true)
    }
}
