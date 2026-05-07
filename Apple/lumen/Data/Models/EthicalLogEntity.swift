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
    var contentSafetyFlags: [String]
    var userFeedback: UserFeedback?
    var privacyScope: String
    var ttsProvider: String?

    init(from log: EthicalLog) {
        self.id = log.id
        self.timestamp = log.timestamp
        self.provider = log.provider
        self.mode = log.mode
        self.latencyMs = log.latencyMs
        self.tokenIn = log.tokenIn
        self.tokenOut = log.tokenOut
        self.promptHash = log.promptHash
        self.contentSafetyFlags = log.contentSafetyFlags
        self.userFeedback = log.userFeedback
        self.privacyScope = log.privacyScope
        self.ttsProvider = log.ttsProvider
    }

    func toDomain() -> EthicalLog {
        EthicalLog(
            id: id,
            timestamp: timestamp,
            provider: provider,
            mode: mode,
            latencyMs: latencyMs,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            promptHash: promptHash,
            contentSafetyFlags: contentSafetyFlags,
            userFeedback: userFeedback,
            privacyScope: privacyScope,
            ttsProvider: ttsProvider
        )
    }
}
