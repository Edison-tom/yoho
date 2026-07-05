import SwiftUI
import AVKit

struct AlphaMP4Player: View {
    let fileName: String
    let isLooping: Bool
    var onFinish: (@Sendable () -> Void)?

    @State private var player: AVPlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .allowsHitTesting(false)
                    .onDisappear {
                        player.pause()
                    }
            } else {
                Color.clear
            }
        }
        .onAppear { loadVideo() }
        .onChange(of: fileName) { _, _ in
            player?.pause()
            player = nil
            looper = nil
            loadVideo()
        }
    }

    private func loadVideo() {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else {
            return
        }

        let item = AVPlayerItem(url: url)
        let newPlayer: AVPlayer

        if isLooping {
            let queuePlayer = AVQueuePlayer(playerItem: item)
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            newPlayer = queuePlayer
        } else {
            newPlayer = AVPlayer(playerItem: item)
        }

        newPlayer.isMuted = true

        if !isLooping, let finish = onFinish {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { _ in
                finish()
            }
        }

        player = newPlayer
        newPlayer.play()
    }
}
