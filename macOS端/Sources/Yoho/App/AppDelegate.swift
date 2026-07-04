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
            createFloatingWindow()
            appState.focusTimer.start()
        }
    }

    nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.focusTimer.stop()
        mouseTracker?.stop()
    }

    private func createFloatingWindow() {
        let contentView = ContentView()
            .environment(appState)

        let hostingView = NSHostingView(rootView: contentView)

        let window = FloatingWindow(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Constants.windowWidth,
                height: Constants.windowHeight
            )
        )
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.floatingWindow = window

        mouseTracker = MouseTracker(window: window)
        mouseTracker?.start()

        NSApp.activate(ignoringOtherApps: true)
    }
}
