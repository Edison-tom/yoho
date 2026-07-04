import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        if appState.isFirstLaunch {
            OnboardingView()
        } else {
            FloatingWindowView()
        }
    }
}
