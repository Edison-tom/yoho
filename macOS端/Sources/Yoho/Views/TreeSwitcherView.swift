import SwiftUI

struct TreeSwitcherView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        let trees = appState.treeStore.visibleTrees
        if trees.count <= 1 { EmptyView() }
        else {
            HStack(spacing: 8) {
                ForEach(Array(trees.prefix(3))) { tree in
                    Button {
                        appState.treeStore.switchToTree(tree.id)
                    } label: {
                        VStack(spacing: 1) {
                            Image(systemName: treeIcon(for: tree.stage))
                                .font(.system(size: 14))
                            Text(tree.name)
                                .font(.system(size: 8))
                                .lineLimit(1)
                        }
                        .padding(4)
                        .background(
                            tree.id == appState.treeStore.activeTree?.id
                                ? Color.yohoGreen.opacity(0.2)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                if trees.count > 3 {
                    Text("+\(trees.count - 3)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func treeIcon(for stage: TreeStage) -> String {
        switch stage {
        case .seed: "circle.fill"
        case .sprout: "leaf.fill"
        case .growing: "tree.fill"
        case .lush, .blooming, .fruiting: "tree.fill"
        }
    }
}
