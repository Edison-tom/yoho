import SwiftUI

struct TreeView: View {
    let tree: Tree
    var isDragTarget: Bool = false

    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    @State private var swayAngle: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                stageVisual
                    .scaleEffect(scale)
                    .overlay(alignment: .top) {
                        if isDragTarget {
                            Text("⭐")
                                .font(.system(size: 18))
                                .offset(y: -20)
                        }
                    }
                if glowOpacity > 0 {
                    Circle()
                        .fill(Color.yohoGreen.opacity(glowOpacity * 0.3))
                        .frame(width: 80, height: 80)
                        .blur(radius: 15)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: 100, height: 90)

            Text(tree.stage.label)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.white.opacity(0.2), in: Capsule())

            progressBar
                .padding(.top, 2)
        }
        .onAppear { startStageAnimation() }
        .onChange(of: tree.stage) { oldValue, newValue in
            playTransition(from: oldValue, to: newValue)
        }
    }

    // MARK: - 阶段视觉

    @ViewBuilder
    private var stageVisual: some View {
        switch tree.stage {
        case .seed:     seedStage
        case .sprout:   sproutStage
        case .growing:  growingStage
        case .lush:     lushStage
        case .blooming: bloomingStage
        case .fruiting: fruitingStage
        }
    }

    private var seedStage: some View {
        ZStack {
            potShape.fill(potGradient).frame(width: 60, height: 50)
            HalfCircle()
                .fill(Color(red: 0.35, green: 0.2, blue: 0.1))
                .frame(width: 52, height: 16)
                .offset(y: -13)
            Circle()
                .fill(Color.yohoGreen)
                .frame(width: 8, height: 8)
                .offset(y: -8)
                .opacity(0.4 + tree.stageProgress * 0.6)
                .blur(radius: 1)
                .animation(.easeInOut(duration: 2).repeatForever(), value: tree.stageProgress)
        }
    }

    private var sproutStage: some View {
        ZStack {
            potShape.fill(potGradient).frame(width: 60, height: 50)
            Capsule()
                .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                .frame(width: 3, height: 25)
                .offset(y: -35)
                .rotationEffect(.degrees(swayAngle), anchor: .bottom)
            leafView.offset(x: -7, y: -44).rotationEffect(.degrees(-30))
            leafView.offset(x: 7, y: -42).rotationEffect(.degrees(30))
        }
    }

    private var growingStage: some View {
        ZStack {
            potShape.fill(potGradient).frame(width: 60, height: 40)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.4, green: 0.25, blue: 0.1))
                .frame(width: 6, height: 40)
                .offset(y: -30)
            HStack(spacing: 20) {
                Circle().fill(Color.green.opacity(0.6)).frame(width: 16, height: 16)
                Circle().fill(Color.green.opacity(0.5)).frame(width: 20, height: 20)
            }
            .offset(y: -42)
            .rotationEffect(.degrees(swayAngle * 0.3), anchor: .bottom)
        }
    }

    private var lushStage: some View {
        ZStack {
            potShape.fill(potGradient).frame(width: 60, height: 40)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.35, green: 0.2, blue: 0.08))
                .frame(width: 8, height: 45)
                .offset(y: -30)
            Circle()
                .fill(LinearGradient(colors: [.green, Color(red: 0.1, green: 0.5, blue: 0.2)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 50, height: 45)
                .offset(y: -52)
                .rotationEffect(.degrees(swayAngle * 0.4), anchor: .bottom)
            budView.offset(x: -14, y: -55)
            budView.offset(x: 12, y: -50)
            budView.offset(x: 5, y: -58)
        }
    }

    private var bloomingStage: some View {
        ZStack {
            potShape.fill(potGradient).frame(width: 60, height: 40)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.3, green: 0.18, blue: 0.06))
                .frame(width: 9, height: 50)
                .offset(y: -30)
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.7, green: 0.9, blue: 0.5),
                                               Color(red: 0.2, green: 0.6, blue: 0.3)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 55, height: 50)
                .offset(y: -54)
                .rotationEffect(.degrees(swayAngle * 0.4), anchor: .bottom)
                .overlay {
                    flowerView.offset(x: -18, y: -12)
                    flowerView.offset(x: 15, y: -8)
                    flowerView.offset(x: -8, y: -18)
                    flowerView.offset(x: 10, y: -14)
                    flowerView.offset(x: 0, y: -6)
                    flowerView.offset(x: -14, y: -5)
                }
            petalView.offset(x: -22, y: -30)
            petalView.offset(x: 18, y: -25)
            petalView.offset(x: -10, y: -20)
            petalView.offset(x: 22, y: -18)
        }
    }

    private var fruitingStage: some View {
        ZStack {
            potShape.fill(potGradient).frame(width: 60, height: 40)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.28, green: 0.15, blue: 0.05))
                .frame(width: 10, height: 55)
                .offset(y: -30)
            Circle()
                .fill(Color.yellow.opacity(0.2))
                .frame(width: 70, height: 70)
                .offset(y: -55)
                .blur(radius: 8)
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.2, green: 0.7, blue: 0.3),
                                               Color(red: 0.1, green: 0.4, blue: 0.2)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 60, height: 55)
                .offset(y: -56)
                .rotationEffect(.degrees(swayAngle * 0.3), anchor: .bottom)
                .overlay {
                    fruitView.offset(x: -20, y: -10)
                    fruitView.offset(x: 16, y: -8)
                    fruitView.offset(x: -10, y: -15)
                    fruitView.offset(x: 10, y: -12)
                    fruitView.offset(x: 0, y: -5)
                }
        }
    }

    // MARK: - 子组件

    private var potGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.7, green: 0.4, blue: 0.25), Color(red: 0.5, green: 0.25, blue: 0.15)],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var potShape: some Shape { AnyShape(Pot()) }

    private var leafView: some View {
        Ellipse()
            .fill(Color(red: 0.3, green: 0.8, blue: 0.4))
            .frame(width: 14, height: 8)
    }

    private var budView: some View {
        Circle()
            .fill(Color.pink.opacity(0.6))
            .frame(width: 5, height: 5)
    }

    private var flowerView: some View {
        Circle()
            .fill(RadialGradient(colors: [.white, .pink], center: .center, startRadius: 0, endRadius: 6))
            .frame(width: 8, height: 8)
    }

    private var petalView: some View {
        Circle()
            .fill(Color.pink.opacity(0.5))
            .frame(width: 4, height: 4)
    }

    private var fruitView: some View {
        Circle()
            .fill(RadialGradient(colors: [.yellow, .orange], center: .center, startRadius: 1, endRadius: 6))
            .frame(width: 10, height: 10)
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.secondary.opacity(0.2)).frame(width: 80, height: 4)
            Capsule()
                .fill(tree.stage == .fruiting ? Color.yellow : Color.yohoGreen)
                .frame(width: 80 * CGFloat(tree.stageProgress), height: 4)
                .animation(.easeInOut(duration: 0.5), value: tree.stageProgress)
        }
        .overlay(alignment: .trailing) {
            Text("\(tree.fertilizerCount)/\(tree.targetFertilizerCount)")
                .font(.system(size: 7)).foregroundStyle(.tertiary).offset(y: 8)
        }
    }

    // MARK: - 动画

    private func startStageAnimation() {
        glowOpacity = tree.stage == .fruiting ? 1 : 0
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            swayAngle = 2
        }
    }

    private func playTransition(from old: TreeStage, to new: TreeStage) {
        withAnimation(.easeOut(duration: 0.1)) { glowOpacity = 1 }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.4)) { scale = 1.2 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.easeOut(duration: 0.3)) { glowOpacity = 0 }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { scale = 1.0 }
            startStageAnimation()
        }
    }
}

// MARK: - Shapes

private struct Pot: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width; let h = rect.height; let rim: CGFloat = 6
        path.move(to: CGPoint(x: w * 0.15, y: 0))
        path.addLine(to: CGPoint(x: w * 0.2, y: rim))
        path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.1, y: h))
        path.addLine(to: CGPoint(x: w * 0.9, y: h))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.8, y: rim))
        path.addLine(to: CGPoint(x: w * 0.85, y: 0))
        path.closeSubpath()
        return path
    }
}

struct HalfCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY),
                    radius: rect.width / 2,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180),
                    clockwise: true)
        return path
    }
}

