import SwiftUI

struct TreeView: View {
    let tree: Tree
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 4) {
            // 树冠
            ZStack {
                if tree.stage == .seed {
                    seedView
                } else {
                    stageImageView
                }

                // 阶段标签气泡
                stageBubble
            }

            // 花盆
            potView
        }
        .onChange(of: tree.stage) { _, _ in
            withAnimation(.spring(duration: Constants.treeStageTransitionDuration)) {
                scale = 1.15
            } completion: {
                withAnimation(.spring(duration: 0.3)) { scale = 1.0 }
            }
        }
    }

    private var seedView: some View {
        ZStack {
            // 土壤横截面
            Circle()
                .fill(Color.brown.opacity(0.6))
                .frame(width: 50, height: 50)

            // 种子发光
            Circle()
                .fill(Color.yohoGreen)
                .frame(width: 12, height: 12)
                .opacity(0.3 + tree.stageProgress * 0.7)
                .blur(radius: 2)
                .animation(.easeInOut(duration: 2).repeatForever(), value: tree.stageProgress)
        }
    }

    private var stageImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.15))

            Image(systemName: stageIcon)
                .font(.system(size: 36))
                .foregroundStyle(.green)
        }
        .frame(width: 70, height: 70)
        .scaleEffect(scale)
    }

    private var stageBubble: some View {
        VStack {
            Text(tree.stage.label)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .offset(y: -40)
        }
    }

    private var potView: some View {
        VStack(spacing: 2) {
            // 花盆本体
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.brown.opacity(0.5))
                .frame(width: 50, height: 8)

            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.yohoGreen)
                        .frame(
                            width: geo.size.width * CGFloat(tree.stageProgress),
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.5), value: tree.stageProgress)
                }
            }
            .frame(width: 60, height: 4)
        }
    }

    private var stageIcon: String {
        switch tree.stage {
        case .seed: return "circle.fill"
        case .sprout: return "leaf.fill"
        case .growing: return "tree.fill"
        case .lush: return "leaf.arrow.circlepath"
        case .blooming: return "sparkles"
        case .fruiting: return "crown.fill"
        }
    }
}
