import SwiftUI

struct PetView: View {
    let breed: PetBreed
    let state: PetState
    let name: String
    var role: Pet.Role = .personal
    var visitingOwnerName: String? = nil  // 串门宠物主人昵称

    var cookieCount: Int = 0
    var onFeed: (() -> Void)?
    var onPet: (() -> Void)?
    var onLongPress: (() -> Void)?

    @State private var isDragTarget = false
    @State private var isPressed = false
    @State private var cookieDragOffset: CGSize = .zero
    @State private var localCookieCount = 0

    var body: some View {
        VStack(spacing: 2) {
            // 宠物名
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            // 串门标识
            if role == .visiting, let owner = visitingOwnerName {
                Text("来自 \(owner)")
                    .font(.system(size: 8))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.7), in: Capsule())
            }

            // 动画本体 + 拖拽目标
            ZStack {
                PetAnimationView(
                    breed: breed,
                    state: state,
                    onAnimationFinish: {
                        // 微动作/起床等自动恢复已由 PetStore 处理
                    }
                )
                .scaleEffect(isPressed ? 0.9 : (isDragTarget ? 1.05 : 1.0))
                .overlay(alignment: .top) {
                    if isDragTarget {
                        Text("🍪")
                            .font(.system(size: 20))
                            .offset(y: -30)
                    }
                }
            }
            .onTapGesture {
                isPressed = true
                onPet?()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                onLongPress?()
            }
            .dropDestination(for: String.self) { items, _ in
                guard items.contains("cookie"), cookieCount > 0 else { return false }
                onFeed?()
                return true
            } isTargeted: { targeted in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isDragTarget = targeted
                }
            }

            // 状态标签
            if state != .idle, !state.label.isEmpty {
                Text(state.label)
                    .font(.system(size: 9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.2), in: Capsule())
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}
