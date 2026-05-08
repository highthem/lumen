import Foundation
import AVFoundation

@MainActor
final class AudioPlayer: AudioPlaying {
    private var player: AVAudioPlayer?
    private let session: AudioSessionManager
    private let soundProvider: any SoundProviding

    init(session: AudioSessionManager, soundProvider: any SoundProviding) {
        self.session = session
        self.soundProvider = soundProvider
    }

    func configureSession() async throws {
        try await session.configureSession()
    }

    func play(soundId: String, fadeIn: Bool) async throws {
        let url: URL?
        if let entry = soundProvider.sound(id: soundId) {
            url = Bundle.main.url(forResource: entry.resourceName, withExtension: entry.resourceExtension)
        } else {
            url = Bundle.main.url(forResource: soundId, withExtension: "caf")
        }
        guard let url else {
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

    func stop() {
        player?.stop()
        player = nil
    }

    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {
        player?.setVolume(volume, fadeDuration: fadeDuration)
    }
}
