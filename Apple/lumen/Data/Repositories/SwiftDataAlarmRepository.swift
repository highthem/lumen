import Foundation
import SwiftData

@ModelActor
actor SwiftDataAlarmRepository: AlarmRepository {

    func all() async throws -> [Alarm] {
        let descriptor = FetchDescriptor<AlarmEntity>(sortBy: [SortDescriptor(\.createdAt)])
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    func fetch(id: UUID) async throws -> Alarm? {
        let descriptor = FetchDescriptor<AlarmEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func save(_ alarm: Alarm) async throws {
        let entity = AlarmEntity(from: alarm)
        modelContext.insert(entity)
        try modelContext.save()
    }

    func update(_ alarm: Alarm) async throws {
        let id = alarm.id
        let descriptor = FetchDescriptor<AlarmEntity>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw AlarmError.notFound
        }
        entity.update(from: alarm)
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<AlarmEntity>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw AlarmError.notFound
        }
        modelContext.delete(entity)
        try modelContext.save()
    }

    func setActive(id: UUID, isActive: Bool) async throws {
        let descriptor = FetchDescriptor<AlarmEntity>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw AlarmError.notFound
        }
        entity.isActive = isActive
        entity.updatedAt = Date()
        try modelContext.save()
    }
}
