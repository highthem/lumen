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
    private let ritualRepository: (any RitualRepository)?
    private var countdownTask: Task<Void, Never>?
    private var ritualId: UUID?

    init(
        quoteProvider: any QuoteProviding,
        audioPlayer: any AudioPlaying,
        soundProvider: any SoundProviding,
        ritualRepository: (any RitualRepository)? = nil
    ) {
        self.quoteProvider = quoteProvider
        self.audioPlayer = audioPlayer
        self.soundProvider = soundProvider
        self.ritualRepository = ritualRepository
    }

    /// Time spent in presence so far. Used to classify partial vs skipped.
    var elapsed: TimeInterval { 60.0 - remaining }

    func start() async {
        quote = await quoteProvider.random(lang: "fr")

        // Make sure today's ritual exists and capture its id so we can persist
        // presence regardless of whether the user later completes the questionnaire.
        if ritualId == nil, let repo = ritualRepository {
            ritualId = try? await repo.fetchOrCreateToday().id
        }

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

        if isComplete {
            await persistPresence(.completed)
        }
    }

    func skip() {
        countdownTask?.cancel()
        Task { audioPlayer.stop() }
        let endState: PresenceState = elapsed >= 30 ? .partial : .skipped
        Task { await persistPresence(endState) }
        isComplete = true
    }

    private func persistPresence(_ state: PresenceState) async {
        guard let repo = ritualRepository, let id = ritualId else { return }
        try? await repo.updatePresence(ritualId: id, state: state)
    }
}
