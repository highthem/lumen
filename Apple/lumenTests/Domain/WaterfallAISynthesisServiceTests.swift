import XCTest
import SwiftData
@testable import lumen

// MARK: - Inline mocks

final class MockAIProviderClient: AIProviderClient, @unchecked Sendable {
    let name: String
    var shouldSucceed: Bool
    var capturedPrompts: [(system: String, user: String)] = []
    private let lock = NSLock()

    init(name: String, shouldSucceed: Bool = true) {
        self.name = name
        self.shouldSucceed = shouldSucceed
    }

    func synthesize(
        prompt: (system: String, user: String),
        ritualId: UUID,
        mode: AIResponseMode
    ) async throws -> SynthesisAttempt {
        lock.withLock { capturedPrompts.append(prompt) }
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

final class MockRateLimiter: RateLimiting, @unchecked Sendable {
    var canProceedResult = true
    var consumeCallCount = 0
    var resetCallCount = 0
    var remainingSlotsResult = 3
    private let lock = NSLock()

    func canProceed(action: AIAction) async -> Bool { canProceedResult }

    func consume(action: AIAction) async {
        lock.withLock { consumeCallCount += 1 }
    }

    func reset() async {
        lock.withLock { resetCallCount += 1 }
    }

    func remainingSlots(action: AIAction) async -> Int {
        remainingSlotsResult
    }
}

final class MockNetworkReachability: NetworkReachability, @unchecked Sendable {
    var isReachable: Bool
    init(isReachable: Bool) { self.isReachable = isReachable }
    func updates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(isReachable)
        }
    }
}

final class MockEthicalLogRepository: EthicalLogRepository, @unchecked Sendable {
    var savedLogs: [EthicalLog] = []
    private let lock = NSLock()

    func save(_ log: EthicalLog) async throws {
        lock.withLock { savedLogs.append(log) }
    }
    func fetchAll() async throws -> [EthicalLog] { savedLogs }
    func deleteAll() async throws { lock.withLock { savedLogs = [] } }
    func exportJSON() async throws -> Data { Data() }
}

final class MockRitualRepository: RitualRepository, @unchecked Sendable {
    var ritual: Ritual
    var attachedSyntheses: [AIResponse] = []
    private let lock = NSLock()

    init(ritual: Ritual) { self.ritual = ritual }

    func fetchOrCreateToday() async throws -> Ritual { ritual }
    func fetch(id: UUID) async throws -> Ritual? { ritual.id == id ? ritual : nil }
    func fetchByDate(_ date: Date) async throws -> Ritual? { nil }
    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws {}
    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws {
        lock.withLock { attachedSyntheses.append(response) }
    }
    func update(_ ritual: Ritual) async throws {}
}

// MARK: - Test helper

private func makeAnswers(ritualId: UUID) -> [QuestionnaireAnswer] {
    [
        QuestionnaireAnswer(ritualId: ritualId, payload: .mood(level: 7, tag: "Bien")),
        QuestionnaireAnswer(ritualId: ritualId, payload: .gratitude(text: "Ma famille")),
        QuestionnaireAnswer(ritualId: ritualId, payload: .intention(word: "Focus"))
    ]
}

// MARK: - Tests

@MainActor
final class WaterfallAISynthesisServiceTests: XCTestCase {

    // MARK: - Case 1: safety short-circuit on selfHarmCue

    func testSelfHarmCueReturnsSupportTemplate() async throws {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()
        let openai = MockAIProviderClient(name: "openai")
        let stub = AppleIntelligenceProviderStub()

        let schema = Schema([PendingSynthesisEntity.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let mockRitual = Ritual(date: Date())
        let ritualRepo = MockRitualRepository(ritual: mockRitual)
        let queue = SynthesisQueue(modelContainer: container, ritualRepository: ritualRepo)

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

        let answers = [QuestionnaireAnswer(ritualId: ritualId, payload: .intention(word: "kill myself"))]
        let result = try await sut.synthesize(answers: answers, ritualId: ritualId, mode: .auto)

        guard case .ready(let response) = result else {
            return XCTFail("Expected .ready with support template")
        }
        XCTAssertEqual(response.provider, .supportTemplate)
        XCTAssertFalse(openai.capturedPrompts.isEmpty == false || openai.capturedPrompts.count > 0,
                       "OpenAI should NOT have been called")
        XCTAssertTrue(openai.capturedPrompts.isEmpty, "Cloud provider must not be called for selfHarmCue")
    }

    // MARK: - Case 2: rate limit throws

    func testRateLimitedThrows() async {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()
        rateLimiter.canProceedResult = false

        let schema = Schema([PendingSynthesisEntity.self])
        let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let mockRitual = Ritual(date: Date())
        let ritualRepo = MockRitualRepository(ritual: mockRitual)
        let queue = SynthesisQueue(modelContainer: container, ritualRepository: ritualRepo)

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
            XCTFail("Should have thrown AIError.rateLimited")
        } catch AIError.rateLimited {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Case 3: first cloud provider succeeds

    func testFirstCloudProviderSucceeds() async throws {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()
        let openai = MockAIProviderClient(name: "openai", shouldSucceed: true)
        let anthropic = MockAIProviderClient(name: "anthropic", shouldSucceed: true)

        let schema = Schema([PendingSynthesisEntity.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let mockRitual = Ritual(date: Date())
        let ritualRepo = MockRitualRepository(ritual: mockRitual)
        let queue = SynthesisQueue(modelContainer: container, ritualRepository: ritualRepo)

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
            return XCTFail("Expected .ready")
        }
        XCTAssertEqual(response.provider, .openai)
        XCTAssertTrue(anthropic.capturedPrompts.isEmpty, "Anthropic should not be called if OpenAI succeeds")
    }

    // MARK: - Case 4: first cloud fails, fallback to second

    func testFallbackToSecondCloudProvider() async throws {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()
        let openai = MockAIProviderClient(name: "openai", shouldSucceed: false)
        let anthropic = MockAIProviderClient(name: "anthropic", shouldSucceed: true)

        let schema = Schema([PendingSynthesisEntity.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let mockRitual = Ritual(date: Date())
        let ritualRepo = MockRitualRepository(ritual: mockRitual)
        let queue = SynthesisQueue(modelContainer: container, ritualRepository: ritualRepo)

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
            return XCTFail("Expected .ready from anthropic fallback")
        }
        XCTAssertEqual(response.provider, .anthropic)
    }

    // MARK: - Case 5: offline → queued

    func testOfflineQueuesRequest() async throws {
        let ritualId = UUID()
        let logRepo = MockEthicalLogRepository()
        let ethicalLogger = EthicalLogger(repository: logRepo)
        let rateLimiter = MockRateLimiter()

        let schema = Schema([PendingSynthesisEntity.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let mockRitual = Ritual(date: Date())
        let ritualRepo = MockRitualRepository(ritual: mockRitual)
        let queue = SynthesisQueue(modelContainer: container, ritualRepository: ritualRepo)

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
            return XCTFail("Expected .queued when offline and no on-device AI")
        }
    }
}
