import Foundation
import AVFoundation

struct AudioSessionManager: Sendable {

    func configureSession() async throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try AVAudioSession.sharedInstance().setActive(true)
    }

    func deactivate() async {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
