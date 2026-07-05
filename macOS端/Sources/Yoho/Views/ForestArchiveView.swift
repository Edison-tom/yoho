import SwiftUI

struct ForestArchiveView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("🌲 森林档案")
                .font(.headline)

            if appState.treeStore.archivedTrees.isEmpty {
                Text("还没有达成封存的树")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                List(appState.treeStore.archivedTrees) { tree in
                    HStack {
                        Image(systemName: tree.stage == .fruiting ? "tree.fill" : "leaf.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tree.name).font(.body)
                            Text(tree.goal.title).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(tree.completedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(minHeight: 100)
            }

            Button("关闭") { dismiss() }
                .buttonStyle(.plain)
                .font(.caption)
        }
        .frame(width: 260, height: 280)
        .padding()
    }
}
