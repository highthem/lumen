import Foundation
import SwiftData

@ModelActor
actor SwiftDataAlarmRepository: AlarmRepository {

    func all() async throws -> [Alarm] {
        let descriptor = FetchDescriptor<AlarmEntity>(sortBy: [SortDescriptor(\.createdAt)])
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(id: UUID) async throws -> Alarm? {
        try fetchEntity(id: id)?.toDomain()
    }

    func save(_ alarm: Alarm) async throws {
        modelContext.insert(AlarmEntity(from: alarm))
        try modelContext.save()
    }

    func update(_ alarm: Alarm) async throws {
        guard let entity = try fetchEntity(id: alarm.id) else { throw AlarmError.notFound }
        entity.time = alarm.time
        entity.recurrence = alarm.recurrence
        entity.soundId = alarm.soundId
        entity.isActive = alarm.isActive
        entity.snoozeCount = alarm.snoozeCount
        entity.updatedAt = alarm.updatedAt
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        guard let entity = try fetchEntity(id: id) else { throw AlarmError.notFound }
        modelContext.delete(entity)
        try modelContext.save()
    }

    func setActive(id: UUID, isActive: Bool) async throws {
        guard let entity = try fetchEntity(id: id) else { throw AlarmError.notFound }
        entity.isActive = isActive
        entity.updatedAt = Date()
        try modelContext.save()
    }

    private func fetchEntity(id: UUID) throws -> AlarmEntity? {
        try modelContext.fetch(FetchDescriptor<AlarmEntity>(predicate: #Predicate { $0.id == id })).first
    }
}
