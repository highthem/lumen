import Foundation
import Testing
import SwiftData
@testable import lumen

// MARK: - Inline mocks

actor MockAIProviderClient: AIProviderClient {
    let name: String
    var shouldSucceed: Bool
    private(set) var capturedPrompts: [SimplePrompt] = []

    struct SimplePrompt: Sendable {
        let system: String
        let user: String
    }

    init(name: String, shouldSucceed: Bool = true) {
        self.name = name
        self.shouldSucceed = shouldSucceed
    }

    func setShouldSucceed(_ value: Bool) { shouldSucceed = value }

    func synthesize(
        prompt: (system: String, user: String),
        ritualId: UUID,
        mode: AIResponseMode
    ) async throws -> SynthesisAttempt {
        capturedPrompts.append(SimplePrompt(system: prompt.system, user: prompt.user))
        guard shouldSucceed else {
            throw AIError.providerFailed(name)
        }
        return SynthesisAttempt(
            response: AIResponse(
                ritualId: ritualId,
                intention: "Mock intention from \(name)",
                focus: ["Focus 1"],
                reminder: "Stay on track",
                provider: AIProvider(rawValue: name) ?? .openai,
                mode: mode
            ),
            latencyMs: 100,
            tokenIn: 50,
            tokenOut: 80
        )
    }
}

actor MockRateLimiter: RateLimiting {
    var canProceedResult = true
    private(set) var consumeCallCount = 0
    private(set) var resetCallCount = 0
    var remainingSlotsResult = 3

    func setCanProceedResult(_ value: Bool) { canProceedResult = value }

    func canProceed(action: AIAction) async -> Bool { canProceedResult }

    func consume(action: AIAction) async {
        consumeCallCount += 1
    }

    func reset() async {
        resetCallCount += 1
    }

    func remainingSlots(action: AIAction) async -> Int {
        remainingSlotsResult
    }
}

final class MockNetworkReachability: NetworkReachability {
    let isReachableValue: Bool
    init(isReachable: Bool) { self.isReachableValue = isReachable }
    var isReachable: Bool { get async { isReachableValue } }
}

actor MockEthicalLogRepository: EthicalLogRepository {
    private(set) var savedLogs: [EthicalLog] = []

    func save(_ log: EthicalLog) async throws {
        savedLogs.append(log)
    }
    func fetchAll() async throws -> [EthicalLog] { savedLogs }
    func fetchAll(limit: Int, offset: Int) async throws -> [EthicalLog] {
        Array(savedLogs.dropFirst(offset).prefix(limit))
    }
    func deleteAll() async throws { savedLogs = [] }
    func exportJSON() async throws -> Data { Data() }
}

actor MockRitualRepository: RitualRepository {
    var ritual: Ritual
    private(set) var attachedSyntheses: [AIResponse] = []

    init(ritual: Ritual) { self.ritual = ritual }

    func fetchOrCreateToday() async throws -> Ritual { ritual }
    func fetch(id: UUID) async throws -> Ritual? { ritual.id == id ? ritual : nil }
    func fetchByDate(_ date: Date) async throws -> Ritual? { nil }
    func fetchSince(_ date: Date) async throws -> [Ritual] { [] }
    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws {}
    func updatePresence(ritualId: UUID, state: PresenceState) async throws {
        ritual.presence = state
    }
    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws {
        attachedSyntheses.append(response)
    }
    func update(_ ritual: Ritual) async throws {}
    func deleteAll() async throws {}
}

// MARK: - Test helper

private func makeAnswers(ritualId: UUID) -> [QuestionnaireAnswer] {
    [
        QuestionnaireAnswer(ritualId: ritualId, payload: .mood(level: 7, tag: "Bien")),
        QuestionnaireAnswer(ritualId: ritualId, payload: .energy(level: .charged)),
        QuestionnaireAnswer(ritualId: ritualId, payload: .gratitude(text: "Ma famille"))
    ]
}

// MARK: - Tests

@Suite("WaterfallAISynthesisService")
@MainActor
struct WaterfallAISynthesisServiceTests {

    // MARK: - Case 1: safety short-circuit on selfHarmCue

    @Test("selfHarmCue returns support template without calling cloud provider")
    func selfHarmCueReturnsSupportTemplate() async throws {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()
        let openai = MockAIProviderClient(name: "openai")
        let stub = AppleIntelligenceProviderStub()

        let schema = Schema([RitualEntity.self, PendingSynthesisEntity.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let queue = SynthesisQueue(modelContainer: container)

        let sut = WaterfallAISynthesisService(
            cloudClients: [openai],
            onDevice: stub,
            onDeviceAvailable: { false },
            queue: queue,
            rateLimiter: rateLimiter,
            ethicalLogger: ethicalLogger,
            contentSafety: ContentSafetyDetector(),
            supportResources: SupportResourcesProvider(),
            reachability: MockNetworkReachability(isReachable: true)
        )

        let answers = [QuestionnaireAnswer(ritualId: ritualId, payload: .gratitude(text: "kill myself"))]
        let result = try await sut.synthesize(answers: answers, ritualId: ritualId, mode: .auto)

        guard case .ready(let response) = result else {
            Issue.record("Expected .ready with support template")
            return
        }
        #expect(response.provider == .supportTemplate)
        let prompts = await openai.capturedPrompts
        #expect(prompts.isEmpty)
    }

    // MARK: - Case 2: rate limit throws

    @Test("rate limited throws AIError.rateLimited")
    func rateLimitedThrows() async {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()
        await rateLimiter.setCanProceedResult(false)

        let schema = Schema([RitualEntity.self, PendingSynthesisEntity.self])
        let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let queue = SynthesisQueue(modelContainer: container)

        let sut = WaterfallAISynthesisService(
            cloudClients: [],
            onDevice: AppleIntelligenceProviderStub(),
            onDeviceAvailable: { false },
            queue: queue,
            rateLimiter: rateLimiter,
            ethicalLogger: ethicalLogger,
            contentSafety: ContentSafetyDetector(),
            supportResources: SupportResourcesProvider(),
            reachability: MockNetworkReachability(isReachable: true)
        )

        do {
            _ = try await sut.synthesize(answers: makeAnswers(ritualId: ritualId), ritualId: ritualId, mode: .auto)
            Issue.record("Should have thrown AIError.rateLimited")
        } catch AIError.rateLimited {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Case 3: first cloud provider succeeds

    @Test("first cloud provider succeeds — second is not called")
    func firstCloudProviderSucceeds() async throws {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()
        let openai = MockAIProviderClient(name: "openai", shouldSucceed: true)
        let anthropic = MockAIProviderClient(name: "anthropic", shouldSucceed: true)

        let schema = Schema([RitualEntity.self, PendingSynthesisEntity.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let queue = SynthesisQueue(modelContainer: container)

        let sut = WaterfallAISynthesisService(
            cloudClients: [openai, anthropic],
            onDevice: AppleIntelligenceProviderStub(),
            onDeviceAvailable: { false },
            queue: queue,
            rateLimiter: rateLimiter,
            ethicalLogger: ethicalLogger,
            contentSafety: ContentSafetyDetector(),
            supportResources: SupportResourcesProvider(),
            reachability: MockNetworkReachability(isReachable: true)
        )

        let result = try await sut.synthesize(answers: makeAnswers(ritualId: ritualId), ritualId: ritualId, mode: .auto)

        guard case .ready(let response) = result else {
            Issue.record("Expected .ready")
            return
        }
        #expect(response.provider == .openai)
        let anthropicPrompts = await anthropic.capturedPrompts
        #expect(anthropicPrompts.isEmpty)
    }

    // MARK: - Case 4: first cloud fails, fallback to second

    @Test("first cloud fails — falls back to second cloud provider")
    func fallbackToSecondCloudProvider() async throws {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()
        let openai = MockAIProviderClient(name: "openai", shouldSucceed: false)
        let anthropic = MockAIProviderClient(name: "anthropic", shouldSucceed: true)

        let schema = Schema([RitualEntity.self, PendingSynthesisEntity.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let queue = SynthesisQueue(modelContainer: container)

        let sut = WaterfallAISynthesisService(
            cloudClients: [openai, anthropic],
            onDevice: AppleIntelligenceProviderStub(),
            onDeviceAvailable: { false },
            queue: queue,
            rateLimiter: rateLimiter,
            ethicalLogger: ethicalLogger,
            contentSafety: ContentSafetyDetector(),
            supportResources: SupportResourcesProvider(),
            reachability: MockNetworkReachability(isReachable: true)
        )

        let result = try await sut.synthesize(answers: makeAnswers(ritualId: ritualId), ritualId: ritualId, mode: .auto)

        guard case .ready(let response) = result else {
            Issue.record("Expected .ready from anthropic fallback")
            return
        }
        #expect(response.provider == .anthropic)
    }

    // MARK: - Case 5: offline → queued

    @Test("offline with no on-device AI queues the request")
    func offlineQueuesRequest() async throws {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()

        let schema = Schema([RitualEntity.self, PendingSynthesisEntity.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let queue = SynthesisQueue(modelContainer: container)

        let sut = WaterfallAISynthesisService(
            cloudClients: [],
            onDevice: AppleIntelligenceProviderStub(),
            onDeviceAvailable: { false },
            queue: queue,
            rateLimiter: rateLimiter,
            ethicalLogger: ethicalLogger,
            contentSafety: ContentSafetyDetector(),
            supportResources: SupportResourcesProvider(),
            reachability: MockNetworkReachability(isReachable: false)
        )

        let result = try await sut.synthesize(answers: makeAnswers(ritualId: ritualId), ritualId: ritualId, mode: .auto)

        guard case .queued = result else {
            Issue.record("Expected .queued when offline and no on-device AI")
            return
        }
    }
}
