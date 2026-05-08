import XCTest
@testable import lumen

@MainActor
final class BuildDashboardSnapshotTests: XCTestCase {

    func testNoRitualReturnsEmptySnapshotWithSleepFromService() async throws {
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

        XCTAssertNil(snapshot.mood)
        XCTAssertNil(snapshot.energy)
        XCTAssertNil(snapshot.priority)
        XCTAssertNil(snapshot.gratitude)
        XCTAssertEqual(snapshot.presence, .notStarted)
        XCTAssertEqual(snapshot.sleep?.totalAsleep, sleep.totalAsleep)
    }

    func testFullRitualPopulatesAllAnswerFields() async throws {
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

        XCTAssertEqual(snapshot.mood?.level, 7)
        XCTAssertEqual(snapshot.mood?.tag, "posé")
        XCTAssertEqual(snapshot.energy, .charged)
        XCTAssertEqual(snapshot.priority?.text, "Bloquer 90 min pour le brief.")
        XCTAssertEqual(snapshot.gratitude, "Le silence.")
        XCTAssertEqual(snapshot.presence, .completed)
    }

    func testSleepNilWhenServiceUnauthorized() async throws {
        let ritualRepo = InMemoryRitualRepository()
        let sleepService = MockSleepHealthService(summary: nil, authorized: false)
        let sut = BuildDashboardSnapshot(ritualRepository: ritualRepo, sleepService: sleepService)

        let snapshot = try await sut.execute(date: Date())

        XCTAssertNil(snapshot.sleep)
    }

    func testPresenceReadFromRitual() async throws {
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

        XCTAssertEqual(snapshot.presence, .skipped)
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
