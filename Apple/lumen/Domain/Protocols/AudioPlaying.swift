import Foundation

// `@MainActor` because the only impl wraps `AVAudioPlayer`, which requires
// main-thread invocation on iOS 17+.
@MainActor
protocol AudioPlaying: Sendable {
    func configureSession() async throws
    func play(soundId: String, fadeIn: Bool) async throws
    func stop()
    func setVolume(_ volume: Float, fadeDuration: TimeInterval)
}
