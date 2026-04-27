import Foundation

protocol AudioPlaying: Sendable {
    func configureSession() async throws
    func play(soundId: String, fadeIn: Bool) async throws
    func stop() async
    func setVolume(_ volume: Float, fadeDuration: TimeInterval) async
}
