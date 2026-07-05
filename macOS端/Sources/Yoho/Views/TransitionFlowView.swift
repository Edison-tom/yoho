import SwiftUI

struct TransitionFlowView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss
    @State private var step: TransitionStep = .invite
    @State private var partnerEmail = ""
    @State private var myName = ""
    @State private var callPartner = ""
    @State private var errorMessage: String?

    enum TransitionStep {
        case invite
        case nicknames
        case confirm
        case done
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("💑 建立情侣关系")
                .font(.headline)

            switch step {
            case .invite:
                inviteStep
            case .nicknames:
                nicknamesStep
            case .confirm:
                confirmStep
            case .done:
                doneStep
            }

            HStack(spacing: 12) {
                if step != .done {
                    Button("上一步") {
                        if step == .nicknames { step = .invite }
                        else if step == .confirm { step = .nicknames }
                        errorMessage = nil
                    }
                    .buttonStyle(.plain)
                    .disabled(step == .invite)
                    .opacity(step == .invite ? 0 : 1)
                }

                if step != .done {
                    Button(nextButtonText) { advance() }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                }

                if step == .done {
                    Button("完成") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                }
            }

            if let error = errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .frame(width: 260, height: 300)
        .padding()
    }

    private var nextButtonText: String {
        switch step {
        case .invite: "下一步"
        case .nicknames: "下一步"
        case .confirm: "确认建立关系"
        case .done: ""
        }
    }

    private var inviteStep: some View {
        VStack(spacing: 8) {
            Text("输入对方的 Yoho 账号邮箱")
                .font(.caption).foregroundStyle(.secondary)
            TextField("partner@email.com", text: $partnerEmail)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
        }
    }

    private var nicknamesStep: some View {
        VStack(spacing: 8) {
            Text("设定你们的昵称").font(.caption).foregroundStyle(.secondary)
            TextField("我的昵称", text: $myName).textFieldStyle(.roundedBorder).frame(width: 200)
            TextField("怎么称呼 Ta", text: $callPartner).textFieldStyle(.roundedBorder).frame(width: 200)
        }
    }

    private var confirmStep: some View {
        VStack(spacing: 8) {
            Text("确认信息").font(.caption).foregroundStyle(.secondary)
            Text("对方: \(partnerEmail.isEmpty ? "未填写" : partnerEmail)")
                .font(.caption)
            Text("我是「\(myName.isEmpty ? "未设定" : myName)」，叫 Ta「\(callPartner.isEmpty ? "未设定" : callPartner)」")
                .font(.caption)
        }
    }

    private var doneStep: some View {
        VStack(spacing: 12) {
            Text("🎉").font(.system(size: 36))
            Text("关系已建立！").font(.headline)
            Text("邀请已发送给 \(partnerEmail)").font(.caption).foregroundStyle(.secondary)
            Text("对方确认后，你们将共享一棵树").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func advance() {
        withAnimation {
            switch step {
            case .invite:
                guard !partnerEmail.isEmpty else {
                    errorMessage = "请输入对方邮箱"
                    return
                }
                step = .nicknames
            case .nicknames:
                step = .confirm
            case .confirm:
                // 发送配对请求
                step = .done
            case .done:
                break
            }
            errorMessage = nil
        }
    }
}
