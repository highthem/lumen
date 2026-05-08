import Foundation

struct BuildDashboardSnapshot: Sendable {
    private let ritualRepository: any RitualRepository
    private let sleepService: any SleepHealthProviding

    init(ritualRepository: any RitualRepository, sleepService: any SleepHealthProviding) {
        self.ritualRepository = ritualRepository
        self.sleepService = sleepService
    }

    func execute(date: Date) async throws -> DashboardSnapshot {
        let ritual = try await ritualRepository.fetchByDate(date)

        // Sleep is fetched best-effort; failure or missing data → nil card.
        let sleep = await sleepService.fetchLastNight()

        guard let ritual else {
            return DashboardSnapshot(date: date, presence: .notStarted, sleep: sleep)
        }

        var mood: MoodSummary?
        var energy: EnergyLevel?
        var priority: PrioritySummary?
        var gratitude: String?

        for answer in ritual.answers {
            switch answer.payload {
            case .mood(let level, let tag):
                mood = MoodSummary(level: level, tag: tag)
            case .energy(let level):
                energy = level
            case .priority(let text):
                priority = PrioritySummary(text: text)
            case .gratitude(let text):
                gratitude = text
            }
        }

        return DashboardSnapshot(
            date: date,
            mood: mood,
            energy: energy,
            priority: priority,
            gratitude: gratitude,
            presence: ritual.presence,
            sleep: sleep,
            aiIntention: nil
        )
    }
}
