import Foundation
import Observation

@MainActor
@Observable
final class PresenceTimerViewModel {
    var remaining: TimeInterval = 60.0
    var quote: Quote?
    var isComplete = false

    private let quoteProvider: any QuoteProviding
    private let audioPlayer: any AudioPlaying
    private let soundProvider: any SoundProviding
    private var countdownTask: Task<Void, Never>?

    init(quoteProvider: any QuoteProviding, audioPlayer: any AudioPlaying, soundProvider: any SoundProviding) {
        self.quoteProvider = quoteProvider
        self.audioPlayer = audioPlayer
        self.soundProvider = soundProvider
    }

    func start() async {
        quote = await quoteProvider.random(lang: "fr")

        let soundId = UserDefaults.standard.string(forKey: "lumen.settings.breathingSoundId")
            ?? soundProvider.defaultSound(for: .breathing)?.id
            ?? "breath-aube"
        try? await audioPlayer.configureSession()
        Task { try? await audioPlayer.play(soundId: soundId, fadeIn: true) }

        countdownTask?.cancel()
        countdownTask = Task {
            while remaining > 0 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: LumenDelay.oneSecond)
                if Task.isCancelled { return }
                remaining = max(0, remaining - 1)
            }
            isComplete = true
        }
        await countdownTask?.value
        audioPlayer.stop()
    }

    func skip() {
        countdownTask?.cancel()
        Task { audioPlayer.stop() }
        isComplete = true
    }
}
