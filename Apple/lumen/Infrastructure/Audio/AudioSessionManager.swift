import Foundation
import AVFoundation

final class AudioSessionManager: @unchecked Sendable {

    func configureSession() async throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try AVAudioSession.sharedInstance().setActive(true)
    }

    func deactivate() async {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
