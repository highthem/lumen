import Foundation
import Observation
import UIKit

enum SynthesisState: Sendable {
    case loading
    case ready(AIResponse)
    case queued
    case rateLimited
    case error(String)
}

@MainActor
@Observable
final class SynthesisViewModel {
    var state: SynthesisState = .loading
    var ritualId: UUID
    var ttsPlaying = false
    var ttsCurrentBlock: Int = 0
    var remainingRegens: Int = 3

    private let generateSynthesis: GenerateMorningSynthesis
    private let speakSynthesisUC: SpeakSynthesis
    private let rateLimiter: RateLimiter

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
        } else {
            guard case .ready(let response) = state else { return }
            ttsPlaying = true
            ttsCurrentBlock = 0
            await speakSynthesisUC.execute(response: response)
            ttsPlaying = false
        }
    }

    func stopTTS() async {
        speakSynthesisUC.stop()
        ttsPlaying = false
        ttsCurrentBlock = 0
    }

    // MARK: - Private

    private func runSynthesis(mode: AIResponseMode) async {
        do {
            let result = try await generateSynthesis.execute(ritualId: ritualId, mode: mode)
            switch result {
            case .ready(let response):
                state = .ready(response)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .queued:
                state = .queued
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func updateRemainingRegens() async {
        let used = await rateLimiter.canProceed(action: .manualRegeneration)
        // canProceed returns true if we can still go — derive remaining from shared cap (3)
        remainingRegens = used ? 3 : 0
    }
}
