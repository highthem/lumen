import Foundation

struct StartRitual: Sendable {
    private let ritualRepository: any RitualRepository

    init(ritualRepository: any RitualRepository) {
        self.ritualRepository = ritualRepository
    }

    func execute() async throws -> Ritual {
        try await ritualRepository.fetchOrCreateToday()
    }
}
