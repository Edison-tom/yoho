import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) var appState
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            Text("🌱")
                .font(.system(size: 40))

            Text("欢迎来到 Yoho")
                .font(.title2)
                .fontWeight(.bold)

            Text("种一棵树，养一只宠，赴一个约")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                TextField("邮箱", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .disabled(isLoading)

                SecureField("密码（至少 6 位）", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .disabled(isLoading)
            }
            .padding(.top, 8)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(width: 200)
            }

            VStack(spacing: 6) {
                Button(isRegistering ? "注册" : "登录") {
                    Task { await submit() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.yohoGreen)
                .disabled(email.isEmpty || password.count < 6 || isLoading)

                Button(isRegistering ? "已有账号？登录" : "没有账号？注册") {
                    isRegistering.toggle()
                    errorMessage = nil
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            Button("跳过") {
                appState.isFirstLaunch = false
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .frame(width: 240, height: 320)
        .padding()
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        do {
            if isRegistering {
                try await appState.authService.signUp(email: email, password: password)
            } else {
                try await appState.authService.signIn(email: email, password: password)
            }
            appState.isFirstLaunch = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
