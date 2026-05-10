import Foundation
import Testing
@testable import lumen

@Suite("FetchRitualHistory")
struct FetchRitualHistoryTests {

    private let calendar = Calendar(identifier: .gregorian)
    private let today: Date

    init() {
        today = Calendar(identifier: .gregorian).startOfDay(for: Date())
    }

    @Test("empty repository yields zero completion and zero streak")
    func emptyRepoYieldsZeroCompletionAndZeroStreak() async throws {
        let repo = HistoryRepo(rituals: [])
        let sut = FetchRitualHistory(repository: repo)

        let history = try await sut.execute(reference: today)

        #expect(history.days.count == 7)
        #expect(history.completedCount == 0)
        #expect(history.consecutiveStreak == 0)
        #expect(history.days.allSatisfy { !$0.isCompleted })
        #expect(history.days.last?.isToday == true)
    }

    @Test("three consecutive completed days ending today produces streak of 3")
    func threeConsecutiveCompletedEndingTodayProducesStreakThree() async throws {
        let dates = [-2, -1, 0].map { offset in
            calendar.date(byAdding: .day, value: offset, to: today)!
        }
        let rituals = dates.map { ritual(at: $0, completed: true) }
        let repo = HistoryRepo(rituals: rituals)
        let sut = FetchRitualHistory(repository: repo)

        let history = try await sut.execute(reference: today)

        #expect(history.completedCount == 3)
        #expect(history.consecutiveStreak == 3)
    }

    @Test("gap ending yesterday counts back from yesterday")
    func gapEndingYesterdayCountsBackFromYesterday() async throws {
        // Days: today (incomplete), -1 done, -2 done, -3 done, -4 incomplete
        let dones = [-3, -2, -1].map { offset in
            ritual(at: calendar.date(byAdding: .day, value: offset, to: today)!, completed: true)
        }
        let repo = HistoryRepo(rituals: dones)
        let sut = FetchRitualHistory(repository: repo)

        let history = try await sut.execute(reference: today)

        #expect(history.completedCount == 3)
        #expect(history.consecutiveStreak == 3)
        #expect(history.days.last?.isCompleted == false) // today is empty
    }

    @Test("partial or notStarted rituals do not count toward streak")
    func partialOrNotStartedRitualsDoNotCount() async throws {
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

        #expect(history.completedCount == 0)
        #expect(history.consecutiveStreak == 0)
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
