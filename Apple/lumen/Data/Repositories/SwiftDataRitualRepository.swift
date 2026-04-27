import Foundation
import SwiftData

@ModelActor
actor SwiftDataRitualRepository: RitualRepository {

    // MARK: - RitualRepository

    func fetchOrCreateToday() async throws -> Ritual {
        let today = Calendar.current.startOfDay(for: Date())
        if let entity = try fetchEntity(byDate: today) {
            return entity.toDomain()
        }
        let ritual = Ritual(date: today)
        let entity = RitualEntity(from: ritual)
        modelContext.insert(entity)
        try modelContext.save()
        return ritual
    }

    func fetch(id: UUID) async throws -> Ritual? {
        let descriptor = FetchDescriptor<RitualEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func fetchByDate(_ date: Date) async throws -> Ritual? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return try fetchEntity(byDate: startOfDay)?.toDomain()
    }

    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws {
        let descriptor = FetchDescriptor<RitualEntity>(
            predicate: #Predicate { $0.id == ritualId }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw RitualError.notFound
        }

        var domain = entity.toDomain()
        domain.answers.append(answer)

        let isCompleted = domain.answers.contains { $0.step == .intention }
        domain.state = isCompleted ? .completed : .partial
        if isCompleted && domain.completedAt == nil {
            domain.completedAt = Date()
        }

        entity.update(from: domain)
        try modelContext.save()
    }

    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws {
        let descriptor = FetchDescriptor<RitualEntity>(
            predicate: #Predicate { $0.id == ritualId }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw RitualError.notFound
        }
        var domain = entity.toDomain()
        domain.synthesisId = response.id
        entity.update(from: domain)
        try modelContext.save()
    }

    func update(_ ritual: Ritual) async throws {
        let id = ritual.id
        let descriptor = FetchDescriptor<RitualEntity>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw RitualError.notFound
        }
        entity.update(from: ritual)
        try modelContext.save()
    }

    // MARK: - Helpers

    private func fetchEntity(byDate date: Date) throws -> RitualEntity? {
        let descriptor = FetchDescriptor<RitualEntity>(
            predicate: #Predicate { $0.date == date }
        )
        return try modelContext.fetch(descriptor).first
    }
}

enum RitualError: Error {
    case notFound
}
