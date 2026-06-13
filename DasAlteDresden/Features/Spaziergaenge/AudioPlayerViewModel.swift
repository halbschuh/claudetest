import Foundation
import AVFoundation

@Observable
final class AudioPlayerViewModel {
    private var player: AVPlayer?
    private var timeObserver: Any?

    private(set) var isPlaying = false
    private(set) var progress: Double = 0
    private(set) var currentTimeDisplay = "0:00"
    private(set) var totalTimeDisplay = "0:00"
    private(set) var currentURL: URL?

    func toggle(url: URL) {
        if currentURL == url {
            isPlaying ? pause() : resume()
        } else {
            play(url: url)
        }
    }

    func stop() {
        removeTimeObserver()
        player?.pause()
        player = nil
        isPlaying = false
        progress = 0
        currentTimeDisplay = "0:00"
        totalTimeDisplay = "0:00"
        currentURL = nil
    }

    private func play(url: URL) {
        stop()
        currentURL = url
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        addTimeObserver()
        player?.play()
        isPlaying = true

        Task { @MainActor [weak self] in
            guard let duration = try? await item.asset.load(.duration),
                  duration.isValid, !duration.isIndefinite else { return }
            self?.totalTimeDisplay = Self.format(duration.seconds)
        }
    }

    private func pause() {
        player?.pause()
        isPlaying = false
    }

    private func resume() {
        player?.play()
        isPlaying = true
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self,
                  let duration = self.player?.currentItem?.duration,
                  duration.isValid, !duration.isIndefinite else { return }
            let total = duration.seconds
            let current = time.seconds
            self.progress = total > 0 ? current / total : 0
            self.currentTimeDisplay = Self.format(current)
            self.totalTimeDisplay = Self.format(total)
        }
    }

    private func removeTimeObserver() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
    }

    private static func format(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return "\(m):\(String(format: "%02d", s))"
    }
}
