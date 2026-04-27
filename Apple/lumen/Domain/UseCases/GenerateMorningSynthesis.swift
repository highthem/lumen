import Foundation

struct GenerateMorningSynthesis: Sendable {
    private let ritualRepository: any RitualRepository
    private let aiService: any AISynthesisService

    init(ritualRepository: any RitualRepository, aiService: any AISynthesisService) {
        self.ritualRepository = ritualRepository
        self.aiService = aiService
    }

    func execute(ritualId: UUID, mode: AIResponseMode) async throws -> AIResponseResult {
        guard let ritual = try await ritualRepository.fetch(id: ritualId) else {
            throw AIError.providerFailed("ritual not found")
        }

        let hasMood      = ritual.answers.contains { $0.step == .mood }
        let hasIntention = ritual.answers.contains { $0.step == .intention }
        guard hasMood && hasIntention else {
            throw AIError.providerFailed("missing answers")
        }

        let result = try await aiService.synthesize(answers: ritual.answers, ritualId: ritualId, mode: mode)

        if case .ready(let response) = result {
            try await ritualRepository.attachSynthesis(response, ritualId: ritualId)
        }

        return result
    }
}
