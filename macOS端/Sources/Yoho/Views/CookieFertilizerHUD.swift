import SwiftUI

struct CookieFertilizerHUD: View {
    let cookieCount: Int
    let fertilizerCount: Int

    var body: some View {
        HStack(spacing: 12) {
            // 饼干角标
            HStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.pink)
                Text("\(cookieCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.white.opacity(0.2), in: Capsule())
            .draggable("cookie")

            // 肥料角标
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow)
                Text("\(fertilizerCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.white.opacity(0.2), in: Capsule())
            .draggable("fertilizer")
        }
    }
}
