import SwiftUI

struct PetView: View {
    let breed: PetBreed
    let state: PetState

    var body: some View {
        ZStack {
            // 宠物本体（Lottie 替代：SF Symbol 占位）
            Image(systemName: petSymbol)
                .font(.system(size: Constants.petSize * 0.7))
                .foregroundStyle(breedColor)
                .scaleEffect(state == .eating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: state)

            // 状态气泡
            if state != .idle {
                Text(stateLabel)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .offset(y: -Constants.petSize / 2 - 10)
            }
        }
        .frame(width: Constants.petSize, height: Constants.petSize)
    }

    private var petSymbol: String {
        switch breed {
        case .orangeCat: return "cat.fill"
        case .calicoCat: return "cat.fill"
        case .corgi: return "dog.fill"
        case .goldenRetriever: return "dog.fill"
        }
    }

    private var breedColor: Color {
        switch breed {
        case .orangeCat: return .orange
        case .calicoCat: return .gray
        case .corgi: return .brown
        case .goldenRetriever: return .yellow
        }
    }

    private var stateLabel: String {
        switch state {
        case .idle: return ""
        case .eating: return "吃饼干..."
        case .producing: return "产出中..."
        case .sleeping: return "Zzz"
        case .runningOut: return "该施肥啦!"
        case .visiting: return "串门中..."
        }
    }
}
