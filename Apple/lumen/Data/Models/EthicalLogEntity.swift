import Foundation
import SwiftData

@Model
final class EthicalLogEntity {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var provider: String
    var mode: String
    var latencyMs: Int?
    var tokenIn: Int?
    var tokenOut: Int?
    var promptHash: String
    var flagsData: Data
    var userFeedbackRaw: String?
    var privacyScope: String

    init(from log: EthicalLog) {
        self.id = log.id
        self.timestamp = log.timestamp
        self.provider = log.provider
        self.mode = log.mode
        self.latencyMs = log.latencyMs
        self.tokenIn = log.tokenIn
        self.tokenOut = log.tokenOut
        self.promptHash = log.promptHash
        self.flagsData = (try? JSONEncoder().encode(log.contentSafetyFlags)) ?? Data()
        self.userFeedbackRaw = log.userFeedback?.rawValue
        self.privacyScope = log.privacyScope
    }

    func toDomain() -> EthicalLog {
        let flags = (try? JSONDecoder().decode([String].self, from: flagsData)) ?? []
        let feedback = userFeedbackRaw.flatMap { UserFeedback(rawValue: $0) }
        return EthicalLog(
            id: id,
            timestamp: timestamp,
            provider: provider,
            mode: mode,
            latencyMs: latencyMs,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            promptHash: promptHash,
            contentSafetyFlags: flags,
            userFeedback: feedback,
            privacyScope: privacyScope
        )
    }
}
