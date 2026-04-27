import Foundation

struct ExportEthicalLogs: Sendable {
    private let logRepository: any EthicalLogRepository

    init(logRepository: any EthicalLogRepository) {
        self.logRepository = logRepository
    }

    func execute() async throws -> Data {
        try await logRepository.exportJSON()
    }
}
