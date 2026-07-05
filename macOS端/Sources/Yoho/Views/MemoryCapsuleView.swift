import SwiftUI

struct MemoryCapsuleView: View {
    @Environment(AppState.self) var appState
    @State private var memories: [MemoryEntry] = MemoryEntry.sampleData

    var body: some View {
        VStack(spacing: 10) {
            Text("💊 记忆胶囊")
                .font(.headline)

            ScrollView {
                ForEach(memories) { memory in
                    HStack {
                        Image(systemName: "capsule.fill")
                            .foregroundStyle(.blue.opacity(0.5))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(memory.title).font(.body)
                            Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(memory.emoji).font(.title3)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    Divider()
                }
            }
            .frame(minHeight: 80, maxHeight: 200)
        }
        .frame(width: 240, height: 280)
        .padding()
    }
}

struct MemoryEntry: Identifiable {
    let id = UUID()
    let title: String
    let emoji: String
    let date: Date

    static let sampleData: [MemoryEntry] = [
        MemoryEntry(title: "第一次种下树", emoji: "🌱", date: Date().addingTimeInterval(-86400 * 30)),
        MemoryEntry(title: "第一颗饼干", emoji: "🍪", date: Date().addingTimeInterval(-86400 * 29)),
        MemoryEntry(title: "树开花了", emoji: "🌸", date: Date().addingTimeInterval(-86400 * 14)),
        MemoryEntry(title: "连续专注7天", emoji: "🔥", date: Date().addingTimeInterval(-86400 * 7)),
        MemoryEntry(title: "宠物摸摸头100次", emoji: "✋", date: Date().addingTimeInterval(-86400)),
    ]
}
