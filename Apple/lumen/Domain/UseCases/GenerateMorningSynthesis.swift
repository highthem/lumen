import Foundation

struct GenerateMorningSynthesis: Sendable {
    private let ritualRepository: any RitualRepository
    private let aiService: any AISynthesisService
    private let sleepService: (any SleepHealthProviding)?
    private let ritualSettings: any RitualSettingsReading

    init(
        ritualRepository: any RitualRepository,
        aiService: any AISynthesisService,
        sleepService: (any SleepHealthProviding)? = nil,
        ritualSettings: any RitualSettingsReading
    ) {
        self.ritualRepository = ritualRepository
        self.aiService = aiService
        self.sleepService = sleepService
        self.ritualSettings = ritualSettings
    }

    func execute(ritualId: UUID, mode: AIResponseMode) async throws -> AIResponseResult {
        guard let ritual = try await ritualRepository.fetch(id: ritualId) else {
            throw AIError.providerFailed("ritual not found")
        }

        let hasMood      = ritual.answers.contains { $0.step == .mood }
        let hasGratitude = ritual.answers.contains { $0.step == .gratitude }
        guard hasMood && hasGratitude else {
            throw AIError.providerFailed("missing answers")
        }

        let sleep = await sleepService?.fetchLastNight()
        let context = RitualContext(
            presence: ritual.presence,
            sleep: sleep,
            presenceDurationSeconds: ritualSettings.presenceDurationSeconds
        )

        let result = try await aiService.synthesize(
            answers: ritual.answers,
            ritualId: ritualId,
            mode: mode,
            context: context
        )

        if case .ready(let response) = result {
            try await ritualRepository.attachSynthesis(response, ritualId: ritualId)
        }

        return result
    }
}
