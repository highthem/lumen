import Foundation
import SwiftData

@ModelActor
actor SwiftDataEthicalLogRepository: EthicalLogRepository {

    func save(_ log: EthicalLog) async throws {
        modelContext.insert(EthicalLogEntity(from: log))
        try modelContext.save()
    }

    func fetchAll() async throws -> [EthicalLog] {
        let descriptor = FetchDescriptor<EthicalLogEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func fetchAll(limit: Int, offset: Int) async throws -> [EthicalLog] {
        var descriptor = FetchDescriptor<EthicalLogEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func deleteAll() async throws {
        try modelContext.delete(model: EthicalLogEntity.self)
        try modelContext.save()
    }

    func exportJSON() async throws -> Data {
        let logs = try await fetchAll()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        let logsData = try encoder.encode(logs)
        let logsJSON = try JSONSerialization.jsonObject(with: logsData)

        let export: [String: Any] = [
            "exported_at": ISO8601DateFormatter().string(from: Date()),
            "app_version": version,
            "device_locale": Locale.current.identifier,
            "privacy_scope": "local_user_data_only",
            "logs": logsJSON
        ]

        return try JSONSerialization.data(withJSONObject: export, options: [.prettyPrinted, .sortedKeys])
    }
}
