import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(spacing: 20) {
            Text("🌱")
                .font(.system(size: 48))

            Text("欢迎来到 Yoho")
                .font(.title2)
                .fontWeight(.bold)

            Text("呦吼")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("种一棵树，养一只宠，赴一个约")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("开始") {
                appState.isFirstLaunch = false
            }
            .buttonStyle(.borderedProminent)
            .tint(.yohoGreen)
        }
        .frame(width: 200, height: 240)
    }
}
