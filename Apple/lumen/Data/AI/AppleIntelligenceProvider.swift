import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
final class AppleIntelligenceProvider: AIProviderClient {
    let name = "apple"

    nonisolated static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    func synthesize(
        prompt: (system: String, user: String),
        ritualId: UUID,
        mode: AIResponseMode
    ) async throws -> SynthesisAttempt {
        let session = LanguageModelSession(instructions: prompt.system)
        let start = Date()
        let result = try await session.respond(to: prompt.user)
        let latencyMs = Int(Date().timeIntervalSince(start) * 1000)

        guard let data = result.content.data(using: .utf8),
              let response = try? AIResponse.decodeGeneratedJSON(
                data,
                ritualId: ritualId,
                provider: .apple,
                mode: mode
              ) else {
            throw AIError.decodeFailed
        }

        return SynthesisAttempt(
            response: response,
            latencyMs: latencyMs,
            tokenIn: nil,
            tokenOut: nil
        )
    }
}
#endif

final class AppleIntelligenceProviderStub: AIProviderClient {
    let name = "apple"

    nonisolated static var isAvailable: Bool { false }

    func synthesize(
        prompt: (system: String, user: String),
        ritualId: UUID,
        mode: AIResponseMode
    ) async throws -> SynthesisAttempt {
        throw AIError.providerFailed("apple-intelligence-unavailable")
    }
}
