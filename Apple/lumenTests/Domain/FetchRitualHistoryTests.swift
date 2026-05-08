import XCTest
@testable import lumen

@MainActor
final class FetchRitualHistoryTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private lazy var today: Date = calendar.startOfDay(for: Date())

    func testEmptyRepoYieldsZeroCompletionAndZeroStreak() async throws {
        let repo = HistoryRepo(rituals: [])
        let sut = FetchRitualHistory(repository: repo)

        let history = try await sut.execute(reference: today)

        XCTAssertEqual(history.days.count, 7)
        XCTAssertEqual(history.completedCount, 0)
        XCTAssertEqual(history.consecutiveStreak, 0)
        XCTAssertTrue(history.days.allSatisfy { !$0.isCompleted })
        XCTAssertTrue(history.days.last?.isToday == true)
    }

    func testThreeConsecutiveCompletedEndingTodayProducesStreakThree() async throws {
        let dates = [-2, -1, 0].map { offset in
            calendar.date(byAdding: .day, value: offset, to: today)!
        }
        let rituals = dates.map { ritual(at: $0, completed: true) }
        let repo = HistoryRepo(rituals: rituals)
        let sut = FetchRitualHistory(repository: repo)

        let history = try await sut.execute(reference: today)

        XCTAssertEqual(history.completedCount, 3)
        XCTAssertEqual(history.consecutiveStreak, 3)
    }

    func testGapEndingYesterdayCountsBackFromYesterday() async throws {
        // Days: today (incomplete), -1 done, -2 done, -3 done, -4 incomplete
        let dones = [-3, -2, -1].map { offset in
            ritual(at: calendar.date(byAdding: .day, value: offset, to: today)!, completed: true)
        }
        let repo = HistoryRepo(rituals: dones)
        let sut = FetchRitualHistory(repository: repo)

        let history = try await sut.execute(reference: today)

        XCTAssertEqual(history.completedCount, 3)
        XCTAssertEqual(history.consecutiveStreak, 3)
        XCTAssertFalse(history.days.last?.isCompleted ?? true) // today is empty
    }

    func testPartialOrNotStartedRitualsDoNotCount() async throws {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let partial = Ritual(
            id: UUID(),
            date: yesterday,
            state: .partial,
            answers: [],
            presence: .partial
        )
        let repo = HistoryRepo(rituals: [partial])
        let sut = FetchRitualHistory(repository: repo)

        let history = try await sut.execute(reference: today)

        XCTAssertEqual(history.completedCount, 0)
        XCTAssertEqual(history.consecutiveStreak, 0)
    }

    // MARK: - Helpers

    private func ritual(at date: Date, completed: Bool) -> Ritual {
        Ritual(
            id: UUID(),
            date: date,
            state: completed ? .completed : .partial,
            answers: [],
            presence: completed ? .completed : .notStarted,
            completedAt: completed ? date : nil
        )
    }
}

// MARK: - In-memory repository

private actor HistoryRepo: RitualRepository {
    private var rituals: [Ritual]

    init(rituals: [Ritual]) { self.rituals = rituals }

    func fetchOrCreateToday() async throws -> Ritual { rituals.last ?? Ritual(date: Date()) }
    func fetch(id: UUID) async throws -> Ritual? { rituals.first { $0.id == id } }
    func fetchByDate(_ date: Date) async throws -> Ritual? {
        rituals.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    func fetchSince(_ date: Date) async throws -> [Ritual] {
        rituals.filter { $0.date >= date }.sorted { $0.date < $1.date }
    }
    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws {}
    func updatePresence(ritualId: UUID, state: PresenceState) async throws {}
    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws {}
    func update(_ ritual: Ritual) async throws {}
    func deleteAll() async throws { rituals = [] }
}
