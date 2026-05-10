import Foundation
import Observation

@MainActor
@Observable
final class PresenceTimerViewModel {
    private(set) var totalDuration: TimeInterval
    var remaining: TimeInterval
    var quote: Quote?
    var isComplete = false

    private let quoteProvider: any QuoteProviding
    private let audioPlayer: any AudioPlaying
    private let soundProvider: any SoundProviding
    private let ritualRepository: (any RitualRepository)?
    private var countdownTask: Task<Void, Never>?
    /// The ID of today's ritual once we've fetched-or-created it. Exposed so
    /// the View can hand it to the next stage (questionnaire / synthesis)
    /// instead of generating a placeholder UUID at the cover boundary.
    private(set) var ritualId: UUID?

    /// Cancel the countdown and tear down audio. Called by the view in
    /// `.onDisappear` so we don't keep a 60-second timer alive after the
    /// cover dismisses. (Can't go in `deinit` under Swift 6 strict
    /// concurrency — nonisolated deinit can't touch MainActor state.)
    func stop() {
        countdownTask?.cancel()
        countdownTask = nil
        audioPlayer.stop()
    }

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
        let stored = UserDefaults.standard.object(forKey: "lumen.settings.presenceDurationSeconds") as? Int ?? 60
        let validated = [30, 60, 90, 120].contains(stored) ? stored : 60
        self.totalDuration = TimeInterval(validated)
        self.remaining = TimeInterval(validated)
    }

    /// Time spent in presence so far. Used to classify partial vs skipped.
    var elapsed: TimeInterval { totalDuration - remaining }

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
        Task { @MainActor [audioPlayer] in
            try? await audioPlayer.play(soundId: soundId, fadeIn: true)
        }

        countdownTask?.cancel()
        countdownTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while self.remaining > 0 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: LumenDelay.oneSecond)
                if Task.isCancelled { return }
                self.remaining = max(0, self.remaining - 1)
            }
            self.isComplete = true
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
        let endState: PresenceState = elapsed >= totalDuration / 2 ? .partial : .skipped
        Task { await persistPresence(endState) }
        isComplete = true
    }

    private func persistPresence(_ state: PresenceState) async {
        guard let repo = ritualRepository, let id = ritualId else { return }
        try? await repo.updatePresence(ritualId: id, state: state)
    }
}
