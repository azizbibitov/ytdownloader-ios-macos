import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class PlayerViewModel {
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var showControls: Bool = true

    private(set) var player: AVPlayer?
    private var timeObserver: Any?
    private var hideControlsTask: Task<Void, Never>?

    func load(url: URL) {
        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        player = avPlayer

        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.currentTime = time.seconds
            }
        }

        Task {
            duration = (try? await item.asset.load(.duration).seconds) ?? 0
        }

        avPlayer.play()
        isPlaying = true
        resetControlsTimer()
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        resetControlsTimer()
    }

    func seek(by seconds: TimeInterval) {
        guard let player else { return }
        let target = CMTime(seconds: max(0, min(currentTime + seconds, duration)), preferredTimescale: 600)
        player.seek(to: target)
        resetControlsTimer()
    }

    func seek(to fraction: Double) {
        guard let player else { return }
        let target = CMTime(seconds: fraction * duration, preferredTimescale: 600)
        player.seek(to: target)
    }

    func toggleControls() {
        showControls.toggle()
        if showControls { resetControlsTimer() }
    }

    func cleanup() {
        if let observer = timeObserver { player?.removeTimeObserver(observer) }
        player?.pause()
        player = nil
        hideControlsTask?.cancel()
    }

    private func resetControlsTimer() {
        hideControlsTask?.cancel()
        showControls = true
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            showControls = false
        }
    }
}
