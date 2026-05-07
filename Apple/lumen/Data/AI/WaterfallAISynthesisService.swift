import Foundation

nonisolated final class WaterfallAISynthesisService: AISynthesisService {

    private let cloudClients: [any AIProviderClient]
    private let onDevice: any AIProviderClient
    private let onDeviceAvailable: @Sendable () -> Bool
    private let queue: SynthesisQueue
    private let rateLimiter: any RateLimiting
    private let ethicalLogger: EthicalLogger
    private let contentSafety: ContentSafetyDetector
    private let supportResources: SupportResourcesProvider
    private let reachability: any NetworkReachability

    init(
        cloudClients: [any AIProviderClient],
        onDevice: any AIProviderClient,
        onDeviceAvailable: @Sendable @escaping () -> Bool,
        queue: SynthesisQueue,
        rateLimiter: any RateLimiting,
        ethicalLogger: EthicalLogger,
        contentSafety: ContentSafetyDetector,
        supportResources: SupportResourcesProvider,
        reachability: any NetworkReachability
    ) {
        self.cloudClients = cloudClients
        self.onDevice = onDevice
        self.onDeviceAvailable = onDeviceAvailable
        self.queue = queue
        self.rateLimiter = rateLimiter
        self.ethicalLogger = ethicalLogger
        self.contentSafety = contentSafety
        self.supportResources = supportResources
        self.reachability = reachability
    }

    func synthesize(answers: [QuestionnaireAnswer], ritualId: UUID, mode: AIResponseMode) async throws -> AIResponseResult {
        let action = aiAction(for: mode)

        // Rate limit check
        guard await rateLimiter.canProceed(action: action) else {
            throw AIError.rateLimited
        }

        // Pre-flight safety check on all text inputs
        let fullText = answers.compactMap { answer -> String? in
            switch answer.payload {
            case .mood(_, let tag): return tag
            case .priority(_, let note): return note
            case .gratitude(let text): return text
            case .intention(let word): return word
            }
        }.joined(separator: " ")

        let flags = contentSafety.detect(in: fullText)
        let prompt = PromptBuilder.build(answers: answers)
        let promptHash = PromptBuilder.hash(system: prompt.system, user: prompt.user)

        if flags.contains(.selfHarmCue) {
            try? await ethicalLogger.logSafetyShortCircuit(promptHash: promptHash, flags: flags)
            let template = supportResources.template(for: ritualId)
            return .ready(template)
        }

        // Online path
        if await reachability.isReachable {
            var sawMissingKey = false
            for client in cloudClients {
                do {
                    let attempt = try await client.synthesize(prompt: prompt, ritualId: ritualId, mode: mode)
                    await rateLimiter.consume(action: action)
                    try? await ethicalLogger.logSynthesis(
                        provider: AIProvider(rawValue: client.name) ?? .openai,
                        mode: mode,
                        latencyMs: attempt.latencyMs,
                        tokenIn: attempt.tokenIn,
                        tokenOut: attempt.tokenOut,
                        promptHash: promptHash,
                        flags: flags
                    )
                    return .ready(attempt.response)
                } catch let error as AIError {
                    if case .missingAPIKey = error { sawMissingKey = true }
                    print("⚠️ AI provider \(client.name) failed: \(error)")
                    continue
                } catch {
                    print("⚠️ AI provider \(client.name) failed: \(error)")
                    continue
                }
            }

            // All cloud providers failed — try on-device
            if onDeviceAvailable() {
                do {
                    let attempt = try await onDevice.synthesize(prompt: prompt, ritualId: ritualId, mode: mode)
                    await rateLimiter.consume(action: action)
                    try? await ethicalLogger.logSynthesis(
                        provider: .apple,
                        mode: mode,
                        latencyMs: attempt.latencyMs,
                        tokenIn: nil,
                        tokenOut: nil,
                        promptHash: promptHash,
                        flags: flags
                    )
                    return .ready(attempt.response)
                } catch {
                    print("⚠️ On-device AI failed: \(error)")
                }
            }

            // If every cloud provider explicitly failed with missingAPIKey,
            // surface that to the caller so the UI can offer "open Settings".
            if sawMissingKey && !onDeviceAvailable() {
                throw AIError.missingAPIKey
            }

            try? await queue.enqueue(answers: answers, ritualId: ritualId)
            try? await ethicalLogger.logQueued(promptHash: promptHash)
            return .queued(estimatedDelivery: nil)
        }

        // Offline path
        if onDeviceAvailable() {
            do {
                let attempt = try await onDevice.synthesize(prompt: prompt, ritualId: ritualId, mode: .fallbackOnDevice)
                await rateLimiter.consume(action: action)
                try? await ethicalLogger.logSynthesis(
                    provider: .apple,
                    mode: .fallbackOnDevice,
                    latencyMs: attempt.latencyMs,
                    tokenIn: nil,
                    tokenOut: nil,
                    promptHash: promptHash,
                    flags: flags
                )
                return .ready(attempt.response)
            } catch {
                print("⚠️ Offline on-device AI failed: \(error)")
            }
        }

        try? await queue.enqueue(answers: answers, ritualId: ritualId)
        try? await ethicalLogger.logQueued(promptHash: promptHash)
        return .queued(estimatedDelivery: nil)
    }

    // MARK: - Helpers

    private func aiAction(for mode: AIResponseMode) -> AIAction {
        switch mode {
        case .auto:               return .autoSynthesis
        case .manualRegenerate:   return .manualRegeneration
        case .askLumen:           return .askLumenDashboard
        default:                  return .autoSynthesis
        }
    }
}
