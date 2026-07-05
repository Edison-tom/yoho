import SwiftUI

struct InteractionMenu: View {
    let mode: InteractionMode
    var onAction: (InteractionAction) -> Void
    @State private var isExpanded = false

    enum InteractionMode: Equatable {
        case couple  // 情侣互动
        case buddy   // 老铁互动
        case sis     // 闺蜜互动
    }

    enum InteractionAction: String, CaseIterable {
        case hearts = "❤️ 送爱心"
        case kiss = "💋 送吻"
        case hug = "🤗 抱抱"
        case cookie = "🍪 送饼干"
        case flower = "🌸 送小花"
        case shoulder = "👋 拍肩膀"
        case cheer = "📣 加油"
    }

    private var actions: [InteractionAction] {
        switch mode {
        case .couple: [.hearts, .kiss, .hug, .cookie, .flower]
        case .buddy:  [.shoulder, .cheer, .cookie, .flower]
        case .sis:    [.hearts, .hug, .cookie, .flower, .cheer]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                ForEach(actions, id: \.self) { action in
                    Button(action.rawValue) {
                        onAction(action)
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded = false
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                }
            }

            Button(isExpanded ? "✕" : "互动") {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(mode == .couple ? .pink : .blue)
            .controlSize(.small)
        }
    }
}
