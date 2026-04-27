import Foundation

protocol EthicalLogRepository: Sendable {
    func save(_ log: EthicalLog) async throws
    func fetchAll() async throws -> [EthicalLog]
    func deleteAll() async throws
    func exportJSON() async throws -> Data
}
