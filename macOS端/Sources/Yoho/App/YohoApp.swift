import SwiftUI

@main
struct YohoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Yoho") {
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
