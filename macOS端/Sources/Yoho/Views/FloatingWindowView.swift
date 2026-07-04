import SwiftUI

struct FloatingWindowView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        ZStack {
            // 毛玻璃背景
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)

            VStack(spacing: 8) {
                // 顶部：HUD（饼干 + 肥料）
                CookieFertilizerHUD(
                    cookieCount: appState.focusTimer.cookies,
                    fertilizerCount: appState.petStore.fertilizerCount
                )
                .padding(.top, 10)

                Spacer()

                // 中间：宠物
                PetView(
                    breed: appState.petStore.pet.breed,
                    state: appState.petStore.pet.state
                )

                // 树（如果有）
                if let tree = appState.treeStore.currentTree {
                    TreeView(tree: tree)
                        .padding(.top, 4)
                }

                // 底部：专注计时
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 10))
                    Text("\(appState.focusTimer.todayMinutes) 分钟")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 12)
        }
        .frame(
            width: Constants.windowWidth,
            height: Constants.windowHeight
        )
    }
}
