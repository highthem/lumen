import Foundation
import Observation
import UIKit

enum SynthesisState: Sendable {
    case loading
    case ready(AIResponse)
    case queued
    case rateLimited
    case missingAPIKey
    case error(String)
}

@MainActor
@Observable
final class SynthesisViewModel {
    var state: SynthesisState = .loading
    var ritualId: UUID
    var ttsPlaying = false
    /// Live elapsed seconds of the current narration (driven by the TTS
    /// progress AsyncStream — populated word-by-word for AVSpeech, ~10Hz
    /// for ElevenLabs audio playback).
    var ttsElapsed: Double = 0
    /// Total estimated duration in seconds. Computed from utterance length
    /// for AVSpeech, exact for ElevenLabs (player.duration).
    var ttsDuration: Double = 0
    var remainingRegens: Int = 3

    private let generateSynthesis: GenerateMorningSynthesis
    private let speakSynthesisUC: SpeakSynthesis
    private let rateLimiter: RateLimiter

    /// In-flight synthesis request — cancelled when the user dismisses the
    /// cover, when they tap "Régénérer", or when load() is re-entered. Keeps
    /// us from leaking cloud requests after the view is gone.
    private var synthesisTask: Task<Void, Never>?
    /// Long-running TTS playback — cancelled the same way.
    private var ttsTask: Task<Void, Never>?
    /// Sibling task that consumes the TTS progress AsyncStream while the
    /// narration is active. Cancelled together with `ttsTask`.
    private var ttsProgressTask: Task<Void, Never>?

    init(
        ritualId: UUID,
        generateSynthesis: GenerateMorningSynthesis,
        speakSynthesis: SpeakSynthesis,
        rateLimiter: RateLimiter
    ) {
        self.ritualId = ritualId
        self.generateSynthesis = generateSynthesis
        self.speakSynthesisUC = speakSynthesis
        self.rateLimiter = rateLimiter
    }

    /// Called by the view in `.onDisappear` so we don't keep the cloud
    /// request alive after the cover dismisses. (deinit can't access
    /// MainActor state under Swift 6 strict concurrency.)
    func dispose() {
        synthesisTask?.cancel()
        synthesisTask = nil
        ttsTask?.cancel()
        ttsTask = nil
        ttsProgressTask?.cancel()
        ttsProgressTask = nil
        speakSynthesisUC.stop()
    }

    func load() async {
        state = .loading
        await updateRemainingRegens()
        await runSynthesis(mode: .auto)
    }

    func regenerate() async {
        guard remainingRegens > 0 else {
            state = .rateLimited
            return
        }
        state = .loading
        await runSynthesis(mode: .manualRegenerate)
        await updateRemainingRegens()
    }

    func toggleTTS() async {
        if ttsPlaying {
            await stopTTS()
            return
        }
        guard case .ready(let response) = state else { return }

        ttsTask?.cancel()
        ttsProgressTask?.cancel()
        ttsPlaying = true
        ttsElapsed = 0
        ttsDuration = 0

        // Subscribe BEFORE the speak call so we don't miss the first emit.
        let progressStream = speakSynthesisUC.progress()
        ttsProgressTask = Task { @MainActor [weak self] in
            for await tick in progressStream {
                guard let self, !Task.isCancelled else { break }
                self.ttsElapsed = tick.elapsedSeconds
                self.ttsDuration = tick.totalSeconds
            }
        }

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            // Best-effort audio: ElevenLabs → AVSpeech fallback inside the use case.
            // Failures stay silent (per CLAUDE.md — no technical error UI).
            try? await self.speakSynthesisUC.execute(response: response)
            if !Task.isCancelled {
                self.ttsPlaying = false
                self.ttsProgressTask?.cancel()
                self.ttsProgressTask = nil
            }
        }
        ttsTask = task
        await task.value
    }

    func stopTTS() async {
        ttsTask?.cancel()
        ttsTask = nil
        ttsProgressTask?.cancel()
        ttsProgressTask = nil
        speakSynthesisUC.stop()
        ttsPlaying = false
        ttsElapsed = 0
        ttsDuration = 0
    }

    // MARK: - Private

    private func runSynthesis(mode: AIResponseMode) async {
        synthesisTask?.cancel()

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await self.generateSynthesis.execute(ritualId: self.ritualId, mode: mode)
                try Task.checkCancellation()
                switch result {
                case .ready(let response):
                    self.state = .ready(response)
                case .queued:
                    self.state = .queued
                }
            } catch is CancellationError {
                // View dismissed mid-flight — leave state as-is, the cover is gone.
            } catch let error as AIError {
                if Task.isCancelled { return }
                switch error {
                case .missingAPIKey: self.state = .missingAPIKey
                case .rateLimited:   self.state = .rateLimited
                default:             self.state = .error(String(describing: error))
                }
            } catch {
                if Task.isCancelled { return }
                self.state = .error(error.localizedDescription)
            }
        }
        synthesisTask = task
        await task.value
    }

    private func updateRemainingRegens() async {
        remainingRegens = await rateLimiter.remainingSlots(action: .manualRegeneration)
    }
}
