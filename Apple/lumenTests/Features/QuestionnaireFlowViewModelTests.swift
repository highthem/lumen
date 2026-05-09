import Foundation
import Testing
@testable import lumen

@Suite("Questionnaire voice dictation")
struct QuestionnaireFlowViewModelTests {

    @Test("priority hold release finishes capture and applies final transcript")
    @MainActor
    func priorityFinishAppliesFinalTranscript() async throws {
        let transcriber = ControlledVoiceTranscriber()
        let vm = makeViewModel(transcriber: transcriber, initialStep: .priority)

        vm.startDictation(for: .priority)
        await transcriber.waitUntilStarted()
        transcriber.emit(.listening)
        await Task.yield()
        #expect(vm.priorityMicState == .listening)

        await vm.finishDictation(for: .priority)
        transcriber.emit(.transcribed("Bloquer 90 minutes pour le brief."))
        transcriber.emit(.finished)
        await Task.yield()

        #expect(transcriber.finishCount == 1)
        #expect(transcriber.cancelCount == 0)
        #expect(vm.priorityText == "Bloquer 90 minutes pour le brief.")
        #expect(vm.priorityMicState == .transcribed)
    }

    @Test("gratitude hold release finishes capture and applies final transcript")
    @MainActor
    func gratitudeFinishAppliesFinalTranscript() async throws {
        let transcriber = ControlledVoiceTranscriber()
        let vm = makeViewModel(transcriber: transcriber, initialStep: .gratitude)

        vm.startDictation(for: .gratitude)
        await transcriber.waitUntilStarted()
        transcriber.emit(.listening)
        await Task.yield()
        #expect(vm.micState == .listening)

        await vm.finishDictation(for: .gratitude)
        transcriber.emit(.transcribed("Le silence avant le lever."))
        transcriber.emit(.finished)
        await Task.yield()

        #expect(transcriber.finishCount == 1)
        #expect(transcriber.cancelCount == 0)
        #expect(vm.gratitudeText == "Le silence avant le lever.")
        #expect(vm.micState == .transcribed)
    }

    @Test("cancel ignores later transcript and returns priority to idle")
    @MainActor
    func cancelIgnoresLaterPriorityTranscript() async throws {
        let transcriber = ControlledVoiceTranscriber()
        let vm = makeViewModel(transcriber: transcriber, initialStep: .priority)

        vm.startDictation(for: .priority)
        await transcriber.waitUntilStarted()
        transcriber.emit(.listening)
        await Task.yield()

        await vm.cancelDictation(for: .priority)
        transcriber.emit(.transcribed("Texte tardif"))
        await Task.yield()

        #expect(transcriber.finishCount == 0)
        #expect(transcriber.cancelCount == 1)
        #expect(vm.priorityText.isEmpty)
        #expect(vm.priorityMicState == .idle)
    }

    @Test("priority audio engine failure opens keyboard fallback")
    @MainActor
    func priorityAudioEngineFailureFallsBackToKeyboard() async throws {
        let transcriber = ControlledVoiceTranscriber()
        let vm = makeViewModel(transcriber: transcriber, initialStep: .priority)

        vm.startDictation(for: .priority)
        await transcriber.waitUntilStarted()
        transcriber.emit(.error(.audioEngineFailed))
        await Task.yield()

        #expect(vm.priorityEditingByKeyboard)
        #expect(vm.priorityMicState == .idle)
    }

    @Test("gratitude audio engine failure opens keyboard fallback")
    @MainActor
    func gratitudeAudioEngineFailureFallsBackToKeyboard() async throws {
        let transcriber = ControlledVoiceTranscriber()
        let vm = makeViewModel(transcriber: transcriber, initialStep: .gratitude)

        vm.startDictation(for: .gratitude)
        await transcriber.waitUntilStarted()
        transcriber.emit(.error(.audioEngineFailed))
        await Task.yield()

        #expect(vm.editingByKeyboard)
        #expect(vm.micState == .idle)
    }

    @MainActor
    private func makeViewModel(
        transcriber: ControlledVoiceTranscriber,
        initialStep: QuestionnaireStep
    ) -> QuestionnaireFlowViewModel {
        let repo = TestRitualRepository()
        return QuestionnaireFlowViewModel(
            startRitual: StartRitual(ritualRepository: repo),
            saveAnswer: SaveQuestionnaireAnswer(ritualRepository: repo),
            dictation: DictateAnswer(transcriber: transcriber),
            initialStep: initialStep
        )
    }
}

private final class ControlledVoiceTranscriber: VoiceTranscribing, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: AsyncStream<VoiceTranscribingState>.Continuation?
    private(set) var finishCount = 0
    private(set) var cancelCount = 0

    func startTranscription(locale: Locale) -> AsyncStream<VoiceTranscribingState> {
        AsyncStream { continuation in
            lock.withLock {
                self.continuation = continuation
            }
        }
    }

    func finishTranscription() async {
        lock.withLock {
            finishCount += 1
        }
    }

    func cancelTranscription() async {
        lock.withLock {
            cancelCount += 1
            continuation?.finish()
        }
    }

    func isOnDeviceSupported(locale: Locale) -> Bool { true }

    func emit(_ state: VoiceTranscribingState) {
        lock.withLock {
            continuation?.yield(state)
        }
    }

    func waitUntilStarted() async {
        for _ in 0..<20 {
            let started = lock.withLock { continuation != nil }
            if started { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}

private actor TestRitualRepository: RitualRepository {
    private var ritual = Ritual(date: Date())

    func fetchOrCreateToday() async throws -> Ritual { ritual }
    func fetch(id: UUID) async throws -> Ritual? { id == ritual.id ? ritual : nil }
    func fetchByDate(_ date: Date) async throws -> Ritual? { ritual }
    func fetchSince(_ date: Date) async throws -> [Ritual] { [ritual] }
    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws {
        ritual.answers.append(answer)
    }
    func updatePresence(ritualId: UUID, state: PresenceState) async throws {
        ritual.presence = state
    }
    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws {
        ritual.synthesisId = response.id
    }
    func update(_ ritual: Ritual) async throws {
        self.ritual = ritual
    }
    func deleteAll() async throws {
        ritual = Ritual(date: Date())
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
