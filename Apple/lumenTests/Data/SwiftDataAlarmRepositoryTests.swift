import Testing
import Foundation
import SwiftData
@testable import lumen

@MainActor
private func makeInMemoryRepo() throws -> SwiftDataAlarmRepository {
    let schema = Schema([AlarmEntity.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    return SwiftDataAlarmRepository(modelContainer: container)
}

@Suite("SwiftDataAlarmRepository")
@MainActor
struct SwiftDataAlarmRepositoryTests {

    @Test("save then fetch by id matches")
    func saveThenFetch() async throws {
        let repo = try makeInMemoryRepo()
        let alarm = Alarm(time: Date(), recurrence: .weekdays)

        try await repo.save(alarm)
        let fetched = try await repo.fetch(id: alarm.id)

        #expect(fetched?.id == alarm.id)
        #expect(fetched?.soundId == alarm.soundId)
    }

    @Test("all() returns correct count after saves")
    func allReturnsCount() async throws {
        let repo = try makeInMemoryRepo()
        let a1 = Alarm(time: Date())
        let a2 = Alarm(time: Date())

        try await repo.save(a1)
        let one = try await repo.all()
        #expect(one.count == 1)

        try await repo.save(a2)
        let two = try await repo.all()
        #expect(two.count == 2)
    }

    @Test("update persists changed time")
    func updatePersistsTime() async throws {
        let repo = try makeInMemoryRepo()
        let original = Alarm(time: Date(timeIntervalSinceReferenceDate: 0))
        try await repo.save(original)

        let newTime = Date(timeIntervalSinceReferenceDate: 7200)
        let updated = Alarm(
            id: original.id,
            time: newTime,
            recurrence: original.recurrence,
            soundId: original.soundId,
            isActive: original.isActive,
            snoozeCount: original.snoozeCount,
            createdAt: original.createdAt,
            updatedAt: Date()
        )
        try await repo.update(updated)

        let fetched = try await repo.fetch(id: original.id)
        #expect(fetched?.time == newTime)
    }

    @Test("delete removes from all()")
    func deleteRemoves() async throws {
        let repo = try makeInMemoryRepo()
        let alarm = Alarm(time: Date())
        try await repo.save(alarm)
        try await repo.delete(id: alarm.id)

        let all = try await repo.all()
        #expect(all.isEmpty)
    }

    @Test("recurrence round-trip: custom mon and fri")
    func recurrenceRoundTrip() async throws {
        let repo = try makeInMemoryRepo()
        let alarm = Alarm(time: Date(), recurrence: .custom([.mon, .fri]))
        try await repo.save(alarm)

        let fetched = try await repo.fetch(id: alarm.id)
        #expect(fetched?.recurrence == .custom([.mon, .fri]))
    }

    @Test("setActive toggles flag to false")
    func setActiveTogglesFlag() async throws {
        let repo = try makeInMemoryRepo()
        let alarm = Alarm(time: Date(), isActive: true)
        try await repo.save(alarm)

        try await repo.setActive(id: alarm.id, isActive: false)

        let fetched = try await repo.fetch(id: alarm.id)
        #expect(fetched?.isActive == false)
    }
}
