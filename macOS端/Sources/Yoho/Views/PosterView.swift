import SwiftUI

struct PosterView: View {
    let tree: Tree
    let todayMinutes: Int
    let petName: String
    let petBreed: PetBreed
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉")
                .font(.system(size: 48))

            Text("目标达成！")
                .font(.title)
                .fontWeight(.bold)

            Text(tree.name)
                .font(.title2)
                .foregroundStyle(.primary)

            VStack(spacing: 4) {
                Text("累计专注 \(todayMinutes) 分钟")
                    .font(.body)
                Text("\(petBreed.rawValue)「\(petName)」一路陪伴")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text(tree.goal.title)
                    .font(.headline)
                Text("种植于 \(tree.plantedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

            Text("树已结果，初心不忘 🌳")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("关闭") { dismiss() }
                    .buttonStyle(.plain)
                Button("种新树") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.yohoGreen)
            }
        }
        .frame(width: 280, height: 360)
        .padding()
    }
}
