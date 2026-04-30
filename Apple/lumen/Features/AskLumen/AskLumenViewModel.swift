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

    let category: DashboardCategory?
    private let aiSynthesis: any AISynthesisService
    private let rateLimiter: any RateLimiting

    init(
        category: DashboardCategory? = nil,
        aiSynthesis: any AISynthesisService,
        rateLimiter: any RateLimiting
    ) {
        self.category = category
        self.aiSynthesis = aiSynthesis
        self.rateLimiter = rateLimiter

        if let category {
            question = "À propos de \(category.displayName.lowercased()), "
        }
    }

    func loadRemaining() async {
        remainingAsks = await rateLimiter.remainingSlots(action: .askLumenDashboard)
    }

    func ask() async {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        state = .loading

        let placeholderAnswer = QuestionnaireAnswer(
            ritualId: UUID(),
            payload: .intention(word: question),
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
