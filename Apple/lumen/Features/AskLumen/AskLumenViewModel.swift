import Foundation
import Observation

enum AskState: Sendable {
    case idle
    case loading
    case ready(AIResponse)
    case rateLimited
    case error(String)
}

@MainActor
@Observable
final class AskLumenViewModel {
    var question: String = ""
    var response: AIResponse?
    var state: AskState = .idle
    var remainingAsks: Int = 3
    var micState: MicState = .idle

    let category: DashboardCategory?
    private let aiSynthesis: any AISynthesisService
    private let rateLimiter: any RateLimiting
    private let dictation: DictateAnswer?
    private var dictationTask: Task<Void, Never>?
    private var questionPrefix: String = ""

    init(
        category: DashboardCategory? = nil,
        aiSynthesis: any AISynthesisService,
        rateLimiter: any RateLimiting,
        dictation: DictateAnswer? = nil
    ) {
        self.category = category
        self.aiSynthesis = aiSynthesis
        self.rateLimiter = rateLimiter
        self.dictation = dictation

        if let category {
            question = "À propos de \(category.displayName.lowercased()), "
        }
    }

    func loadRemaining() async {
        remainingAsks = await rateLimiter.remainingSlots(action: .askLumenDashboard)
    }

    // MARK: - Dictation

    /// Push-to-talk: dictation runs while the user holds the mic. Transcript
    /// is appended to the existing question text so the prefix (category prompt)
    /// stays put.
    func startDictation() {
        guard let dictation else { return }
        questionPrefix = question
        dictationTask?.cancel()
        dictationTask = Task { [weak self] in
            guard let self else { return }
            let stream = dictation.execute(locale: Locale(identifier: "fr_FR"))
            for await event in stream {
                guard !Task.isCancelled else { break }
                handle(event)
            }
        }
    }

    func stopDictation() async {
        dictationTask?.cancel()
        await dictation?.stop()
        if micState == .listening {
            micState = question.isEmpty ? .idle : .transcribed
        }
    }

    private func handle(_ event: VoiceTranscribingState) {
        switch event {
        case .listening:
            micState = .listening
        case .transcribed(let text):
            // Append the live transcript onto the prefix the user already had
            // (e.g. the category prompt). Trim leading whitespace so we don't
            // double-space.
            let separator = (questionPrefix.isEmpty || questionPrefix.hasSuffix(" ")) ? "" : " "
            question = questionPrefix + separator + text
            micState = .transcribed
        case .error:
            micState = .idle
        case .finished:
            if micState == .listening {
                micState = question.isEmpty ? .idle : .transcribed
            }
        }
    }

    func ask() async {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        state = .loading

        let placeholderAnswer = QuestionnaireAnswer(
            ritualId: UUID(),
            payload: .gratitude(text: question),
            createdAt: Date()
        )

        do {
            let result = try await aiSynthesis.synthesize(
                answers: [placeholderAnswer],
                ritualId: UUID(),
                mode: .askLumen
            )
            switch result {
            case .ready(let aiResponse):
                response = aiResponse
                state = .ready(aiResponse)
            case .queued:
                state = .rateLimited
            }
        } catch let error as AIError {
            switch error {
            case .rateLimited:   state = .rateLimited
            case .missingAPIKey: state = .error("Clés API manquantes — voir Réglages.")
            default:             state = .error(String(describing: error))
            }
        } catch {
            state = .error(error.localizedDescription)
        }

        await loadRemaining()
    }
}
