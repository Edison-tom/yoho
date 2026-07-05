import SwiftUI

/// 宠物动画视图
/// 优先播放 Alpha MP4，无素材时降级到 SwiftUI 原生占位动画
struct PetAnimationView: View {
    let breed: PetBreed
    let state: PetState
    var onAnimationFinish: (@Sendable () -> Void)?

    // MARK: - 动画配置

    private var animation: PetAnimation {
        switch state {
        case .idle:           return .idle(for: breed)
        case .eating:         return .eating(for: breed)
        case .producing:      return .producing(for: breed)
        case .sleeping:       return .sleepingLoop(for: breed)
        case .wakingUp:       return .wakingUp(for: breed)
        case .runningOut:     return .reminder(for: breed)
        case .visiting:       return .visitingArrive(for: breed)
        case .petting:        return .petting(for: breed, variant: Int.random(in: 1...3))
        case .stageUp:        return .stageUp(for: breed)
        case .celebrating:    return .celebrating(for: breed)
        case .hungry:         return .hungry(for: breed)
        case .micro(let idx): return .micro(for: breed, index: idx)
        }
    }

    private var particleType: ParticleOverlay.ParticleType? {
        switch state {
        case .petting:  return .heart
        case .eating:   return .sparkle
        case .producing: return .star
        case .stageUp:  return .confetti
        default:        return nil
        }
    }

    // MARK: - 占位动画状态

    @State private var bobOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            if animation.mp4Exists {
                // Alpha MP4 视频
                AlphaMP4Player(
                    fileName: animation.fileName,
                    isLooping: animation.isLooping,
                    onFinish: { onAnimationFinish?() }
                )
            } else {
                // 降级：SwiftUI 占位动画
                fallbackView
            }

            // 粒子叠加
            if let type = particleType {
                ParticleOverlay(type: type, isActive: true)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: Constants.petSize + 20, height: Constants.petSize + 20)
        .onAppear { startFallbackAnimations() }
        .onChange(of: state) { _, _ in startFallbackAnimations() }
    }

    // MARK: - 降级占位视图

    private var fallbackView: some View {
        ZStack {
            // 身体
            bodyShape
                .fill(breedGradient)
                .frame(
                    width: bodySize.width,
                    height: bodySize.height
                )
                .offset(y: bobOffset)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)

            // 眼睛
            eyesView
                .offset(y: bobOffset * 0.3)

            // 耳朵 (猫) / 耳朵 (狗)
            earsView
                .offset(y: bobOffset * 0.5 - bodySize.height * 0.3)
        }
    }

    // MARK: - 身体形状（品种差异）

    private var bodyShape: some Shape {
        switch breed {
        case .silverShaded:
            return AnyShape(Circle())      // 圆润橘猫
        case .ragdoll:
            return AnyShape(Ellipse())     // 修长狸花
        case .poodle:
            return AnyShape(RoundedRectangle(cornerRadius: 12))  // 短腿柯基
        case .goldenRetriever:
            return AnyShape(RoundedRectangle(cornerRadius: 8))   // 大方金毛
        }
    }

    private var bodySize: CGSize {
        let base = Constants.petSize * 0.7
        switch breed {
        case .silverShaded:    return CGSize(width: base, height: base * 0.9)
        case .ragdoll:    return CGSize(width: base * 0.7, height: base * 1.1)
        case .poodle:        return CGSize(width: base * 1.2, height: base * 0.5)
        case .goldenRetriever: return CGSize(width: base * 1.1, height: base * 0.8)
        }
    }

    private var breedGradient: LinearGradient {
        switch breed {
        case .silverShaded:
            LinearGradient(colors: [.orange, .orange.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        case .ragdoll:
            LinearGradient(colors: [Color(white: 0.5), Color(white: 0.3)], startPoint: .top, endPoint: .bottom)
        case .poodle:
            LinearGradient(colors: [Color(red: 0.85, green: 0.65, blue: 0.35), .white], startPoint: .top, endPoint: .bottom)
        case .goldenRetriever:
            LinearGradient(colors: [Color(red: 0.9, green: 0.75, blue: 0.4), Color(red: 0.8, green: 0.6, blue: 0.25)], startPoint: .top, endPoint: .bottom)
        }
    }

    // MARK: - 眼睛

    private var eyesView: some View {
        HStack(spacing: breed == .poodle ? 14 : 10) {
            eyeShape
            eyeShape
        }
    }

    private var eyeShape: some View {
        let isSleeping = state == .sleeping
        return Capsule()
            .fill(.black)
            .frame(width: isSleeping ? 6 : 6, height: isSleeping ? 2 : 6)
    }

    // MARK: - 耳朵

    private var earsView: some View {
        let isCat = breed == .silverShaded || breed == .ragdoll
        return HStack(spacing: bodySize.width * 0.5) {
            Triangle()
                .fill(breedGradient)
                .frame(width: 8, height: isCat ? 14 : 10)
                .rotationEffect(.degrees(isCat ? -15 : -25))
            Triangle()
                .fill(breedGradient)
                .frame(width: 8, height: isCat ? 14 : 10)
                .rotationEffect(.degrees(isCat ? 15 : 25))
        }
    }

    // MARK: - 降级动画

    private func startFallbackAnimations() {
        guard !animation.mp4Exists else { return }

        bobOffset = 0
        rotation = 0
        scale = 1.0

        switch state {
        case .idle:
            withAnimation(.easeInOut(duration: 2 + breedIdleSpeed).repeatForever(autoreverses: true)) {
                bobOffset = -3
            }
        case .eating:
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                scale = 1.15
            }
        case .producing:
            withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
                rotation = 5
            }
        case .sleeping:
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                scale = 0.92
            }
        case .wakingUp:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.05
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                onAnimationFinish?()
            }
        case .runningOut:
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                bobOffset = breed == .poodle ? -10 : -6
            }
            withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                rotation = breed == .poodle ? 10 : 6
            }
        case .visiting:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bobOffset = -5
            }
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                rotation = 3
            }
        case .petting:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.1
            }
            withAnimation(.easeOut(duration: 0.6)) {
                rotation = breed == .poodle ? 15 : 8
            }
        case .stageUp:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.4)) {
                bobOffset = -15
                scale = 1.2
            }
        case .celebrating:
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                bobOffset = -12
            }
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                rotation = breed == .poodle ? 12 : 5
            }
        case .hungry:
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                scale = 0.9
                bobOffset = -2
            }
        case .micro(let idx):
            microAnimation(idx)
        }
    }

    private var breedIdleSpeed: Double {
        switch breed {
        case .silverShaded: return 1.0    // 银渐层 — 温顺慢节奏
        case .ragdoll: return 0.3     // 布偶 — 温柔慵懒
        case .poodle: return 0.5         // 泰迪 — 活泼好动
        case .goldenRetriever: return 0.6
        }
    }

    private func microAnimation(_ idx: Int) {
        switch idx {
        case 1: // 舔爪子
            withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                rotation = 10
            }
        case 2: // 追尾巴
            withAnimation(.linear(duration: 0.6).repeatCount(2, autoreverses: false)) {
                rotation = 360
            }
        case 3: // 打哈欠
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                scale = 1.1
            }
        case 4: // 伸懒腰
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                scale = CGSize(
                    width: bodySize.width * 1.3,
                    height: bodySize.height * 0.8
                ) == bodySize ? 1.15 : 1.05
                bobOffset = 5
            }
        case 5: // 抖毛
            withAnimation(.easeInOut(duration: 0.08).repeatCount(5, autoreverses: true)) {
                rotation = 8
            }
        case 6: // 歪头
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rotation = 25
            }
        default: break
        }

        // 自动恢复
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            onAnimationFinish?()
        }
    }
}

// MARK: - Shape 辅助

private struct Ellipse: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

// 复用已有的 Triangle 和 AnyShape

// MARK: - AnyShape（类型擦除）

struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Triangle

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
