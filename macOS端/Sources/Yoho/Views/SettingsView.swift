import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBreed: PetBreed
    @State private var quoteFrequency: QuoteFrequency
    @State private var stealthMode: Bool

    init() {
        let breed = PetBreed.silverShaded
        _selectedBreed = State(initialValue: breed)
        _quoteFrequency = State(initialValue: .normal)
        _stealthMode = State(initialValue: false)
    }

    var body: some View {
        TabView {
            generalTab.tabItem { Label("通用", systemImage: "gearshape") }
            petTab.tabItem { Label("宠物", systemImage: "pawprint") }
            aboutTab.tabItem { Label("关于", systemImage: "info.circle") }
        }
        .frame(width: 320, height: 280)
    }

    private var generalTab: some View {
        Form {
            Picker("金句频率", selection: $quoteFrequency) {
                ForEach(QuoteFrequency.allCases, id: \.self) { f in
                    Text(f.label).tag(f)
                }
            }
            Toggle("隐身模式（启动后隐藏Dock图标）", isOn: $stealthMode)
            Text("隐身模式将在下次启动时生效").font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }

    private var petTab: some View {
        Form {
            Picker("宠物品种", selection: $selectedBreed) {
                ForEach(PetBreed.allCases, id: \.self) { breed in
                    Text(breed.rawValue).tag(breed)
                }
            }
            HStack {
                Text("当前昵称")
                Spacer()
                Text(appState.myNickname).foregroundStyle(.secondary)
            }
            Button("应用更改") {
                appState.petStore.pet.breed = selectedBreed
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.yohoGreen)
        }
        .padding()
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Text("🌱").font(.system(size: 40))
            Text("Yoho 呦吼").font(.title2).fontWeight(.bold)
            Text("版本 0.1.0").foregroundStyle(.secondary)
            Text("种一棵树，养一只宠，赴一个约")
                .font(.caption).foregroundStyle(.secondary)
            Divider().frame(width: 200)
            Button("导出诊断报告") {
                // P10: diagnostic export
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.plainText]
                panel.nameFieldStringValue = "Yoho_Diagnostic_\(Date().ISO8601Format()).txt"
                if panel.runModal() == .OK, let url = panel.url {
                    try? DiagnosticReport.generate().write(to: url, atomically: true, encoding: .utf8)
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(width: 280, height: 220)
        .padding()
    }
}

enum QuoteFrequency: String, CaseIterable {
    case low, normal, high
    var label: String {
        switch self {
        case .low: "低频"
        case .normal: "标准"
        case .high: "高频"
        }
    }
}
