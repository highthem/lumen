import Foundation

struct EraseEthicalLogs: Sendable {
    private let logRepository: any EthicalLogRepository

    init(logRepository: any EthicalLogRepository) {
        self.logRepository = logRepository
    }

    func execute() async throws {
        try await logRepository.deleteAll()
    }
}
