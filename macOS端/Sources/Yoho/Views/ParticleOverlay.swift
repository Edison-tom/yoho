import SwiftUI

/// 粒子效果叠加层
struct ParticleOverlay: View {
    enum ParticleType {
        case heart      // ❤️ 摸摸头
        case sparkle    // ✨ 投喂
        case star       // ⭐ 排泄
        case confetti   // 🎉 树跃迁

        var symbolName: String {
            switch self {
            case .heart: return "heart.fill"
            case .sparkle: return "sparkle"
            case .star: return "star.fill"
            case .confetti: return "circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .heart: return .pink
            case .sparkle: return .yellow
            case .star: return .yellow
            case .confetti: return .orange
            }
        }

        var count: Int {
            switch self {
            case .heart: return 4
            case .sparkle: return 5
            case .star: return 2
            case .confetti: return 10
            }
        }
    }

    let type: ParticleType
    let isActive: Bool

    @State private var particles: [Particle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: type.symbolName)
                    .font(.system(size: particle.size))
                    .foregroundStyle(type.color)
                    .opacity(particle.opacity)
                    .offset(x: particle.x, y: particle.y)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .frame(width: 80, height: 80)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                emitParticles()
            }
        }
    }

    private func emitParticles() {
        particles = (0..<type.count).map { _ in
            Particle(
                x: CGFloat.random(in: -30...30),
                y: 0,
                size: CGFloat.random(in: 6...14),
                rotation: CGFloat.random(in: -30...30),
                opacity: 1.0
            )
        }

        withAnimation(.easeOut(duration: 1.2)) {
            for i in particles.indices {
                particles[i].y = CGFloat.random(in: -50...(-20))
                particles[i].x += CGFloat.random(in: -20...20)
                particles[i].opacity = 0
            }
        }
    }
}

private struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let rotation: CGFloat
    var opacity: Double
}
