import Foundation
import Testing
@testable import lumen

@Suite("BuildDashboardSnapshot")
@MainActor
struct BuildDashboardSnapshotTests {

    @Test("no ritual returns empty snapshot with sleep from service")
    func noRitualReturnsEmptySnapshotWithSleepFromService() async throws {
        let ritualRepo = InMemoryRitualRepository()
        let sleep = SleepSummary(
            bedtime: Date().addingTimeInterval(-8 * 3600),
            wakeTime: Date(),
            totalAsleep: 6 * 3600,
            deep: 60 * 60,
            rem: 90 * 60,
            core: 4 * 3600,
            awake: 10 * 60
        )
        let sleepService = MockSleepHealthService(summary: sleep, authorized: true)
        let sut = BuildDashboardSnapshot(ritualRepository: ritualRepo, sleepService: sleepService)

        let snapshot = try await sut.execute(date: Date())

        #expect(snapshot.mood == nil)
        #expect(snapshot.energy == nil)
        #expect(snapshot.priority == nil)
        #expect(snapshot.gratitude == nil)
        #expect(snapshot.presence == .notStarted)
        #expect(snapshot.sleep?.totalAsleep == sleep.totalAsleep)
    }

    @Test("full ritual populates all answer fields")
    func fullRitualPopulatesAllAnswerFields() async throws {
        let ritualId = UUID()
        let ritual = Ritual(
            id: ritualId,
            date: Date(),
            state: .completed,
            answers: [
                QuestionnaireAnswer(ritualId: ritualId, payload: .mood(level: 7, tag: "posé")),
                QuestionnaireAnswer(ritualId: ritualId, payload: .energy(level: .charged)),
                QuestionnaireAnswer(ritualId: ritualId, payload: .priority(text: "Bloquer 90 min pour le brief.")),
                QuestionnaireAnswer(ritualId: ritualId, payload: .gratitude(text: "Le silence."))
            ],
            presence: .completed
        )
        let ritualRepo = InMemoryRitualRepository(seed: ritual)
        let sleepService = MockSleepHealthService(summary: nil, authorized: false)
        let sut = BuildDashboardSnapshot(ritualRepository: ritualRepo, sleepService: sleepService)

        let snapshot = try await sut.execute(date: Date())

        #expect(snapshot.mood?.level == 7)
        #expect(snapshot.mood?.tag == "posé")
        #expect(snapshot.energy == .charged)
        #expect(snapshot.priority?.text == "Bloquer 90 min pour le brief.")
        #expect(snapshot.gratitude == "Le silence.")
        #expect(snapshot.presence == .completed)
    }

    @Test("sleep is nil when service is unauthorized")
    func sleepNilWhenServiceUnauthorized() async throws {
        let ritualRepo = InMemoryRitualRepository()
        let sleepService = MockSleepHealthService(summary: nil, authorized: false)
        let sut = BuildDashboardSnapshot(ritualRepository: ritualRepo, sleepService: sleepService)

        let snapshot = try await sut.execute(date: Date())

        #expect(snapshot.sleep == nil)
    }

    @Test("presence is read from the ritual entity")
    func presenceReadFromRitual() async throws {
        let ritualId = UUID()
        let ritual = Ritual(
            id: ritualId,
            date: Date(),
            state: .partial,
            answers: [],
            presence: .skipped
        )
        let ritualRepo = InMemoryRitualRepository(seed: ritual)
        let sleepService = MockSleepHealthService()
        let sut = BuildDashboardSnapshot(ritualRepository: ritualRepo, sleepService: sleepService)

        let snapshot = try await sut.execute(date: Date())

        #expect(snapshot.presence == .skipped)
    }

    @Test("synthesis insights flow into the snapshot")
    func synthesisInsightsFlowIntoSnapshot() async throws {
        let ritualId = UUID()
        let ritual = Ritual(
            id: ritualId,
            date: Date(),
            state: .completed,
            answers: [
                QuestionnaireAnswer(ritualId: ritualId, payload: .mood(level: 2, tag: "posé")),
                QuestionnaireAnswer(ritualId: ritualId, payload: .gratitude(text: "Le silence."))
            ],
            presence: .completed,
            synthesisInsights: [
                .mood: "Posé. Une bonne assise.",
                .gratitude: "Le silence, avant le bruit."
            ]
        )
        let ritualRepo = InMemoryRitualRepository(seed: ritual)
        let sleepService = MockSleepHealthService()
        let sut = BuildDashboardSnapshot(ritualRepository: ritualRepo, sleepService: sleepService)

        let snapshot = try await sut.execute(date: Date())

        #expect(snapshot.insights?[.mood] == "Posé. Une bonne assise.")
        #expect(snapshot.insights?[.gratitude] == "Le silence, avant le bruit.")
    }
}

// MARK: - In-memory ritual repository for tests

private actor InMemoryRitualRepository: RitualRepository {
    private var ritual: Ritual?

    init(seed: Ritual? = nil) {
        self.ritual = seed
    }

    func fetchOrCreateToday() async throws -> Ritual {
        if let ritual { return ritual }
        let new = Ritual(date: Date())
        self.ritual = new
        return new
    }

    func fetch(id: UUID) async throws -> Ritual? {
        ritual?.id == id ? ritual : nil
    }

    func fetchByDate(_ date: Date) async throws -> Ritual? { ritual }

    func fetchSince(_ date: Date) async throws -> [Ritual] {
        guard let ritual, ritual.date >= date else { return [] }
        return [ritual]
    }

    func deleteAll() async throws { ritual = nil }

    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws {
        guard var current = ritual, current.id == ritualId else { return }
        current.answers.append(answer)
        ritual = current
    }

    func updatePresence(ritualId: UUID, state: PresenceState) async throws {
        guard var current = ritual, current.id == ritualId else { return }
        current.presence = state
        ritual = current
    }

    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws {}

    func update(_ ritual: Ritual) async throws { self.ritual = ritual }
}
