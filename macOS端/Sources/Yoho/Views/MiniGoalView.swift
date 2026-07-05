import SwiftUI

struct MiniGoalView: View {
    @Environment(AppState.self) var appState
    @State private var showInput = false
    @State private var goalText = ""

    var body: some View {
        VStack(spacing: 6) {
            if showInput {
                HStack(spacing: 4) {
                    TextField("小目标...", text: $goalText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                    Button("确定") {
                        if !goalText.isEmpty {
                            appState.treeStore.plantTree(
                                name: goalText,
                                goal: Goal(
                                    id: UUID().uuidString,
                                    title: goalText,
                                    goalType: .custom,
                                    targetDate: Date().addingTimeInterval(86400 * 7),
                                    targetAmount: nil, targetUnit: nil, createdAt: Date()
                                ),
                                relationshipType: .personal
                            )
                            goalText = ""
                            showInput = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yohoGreen)
                    .controlSize(.small)
                    Button("取消") { showInput = false }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .controlSize(.small)
                }
            } else {
                Button("📝 设定小目标") {
                    showInput = true
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
