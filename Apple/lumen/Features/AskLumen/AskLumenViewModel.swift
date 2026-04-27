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

    let category: DashboardCategory?
    private let aiSynthesis: any AISynthesisService

    init(category: DashboardCategory? = nil, aiSynthesis: any AISynthesisService) {
        self.category = category
        self.aiSynthesis = aiSynthesis

        if let category {
            question = "À propos de \(category.displayName.lowercased()), "
        }
    }

    func ask() async {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        state = .loading

        // Build a synthetic answer payload from the question text
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
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
