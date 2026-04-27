import Foundation
import AVFoundation

final class AudioPlayer: AudioPlaying, @unchecked Sendable {
    private var player: AVAudioPlayer?
    private let session: AudioSessionManager

    init(session: AudioSessionManager) {
        self.session = session
    }

    func configureSession() async throws {
        try await session.configureSession()
    }

    func play(soundId: String, fadeIn: Bool) async throws {
        guard let url = Bundle.main.url(forResource: soundId, withExtension: "caf") else {
            return
        }
        let p = try AVAudioPlayer(contentsOf: url)
        p.volume = fadeIn ? 0.0 : 1.0
        p.play()
        player = p
        if fadeIn {
            p.setVolume(1.0, fadeDuration: 2.0)
        }
    }

    func stop() async {
        player?.stop()
        player = nil
    }

    func setVolume(_ volume: Float, fadeDuration: TimeInterval) async {
        player?.setVolume(volume, fadeDuration: fadeDuration)
    }
}
