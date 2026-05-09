import Foundation
import Observation

@MainActor
@Observable
final class QuestionnaireFlowViewModel {
    // Navigation
    var step: QuestionnaireStep = .mood
    var ritual: Ritual?

    // Q1 — Mood
    var moodLevel: Int = 2
    var moodTag: String?

    // Q2 — Energy
    /// Slider position 0…4 (corresponds to EnergyLevel by index). Default
    /// to "moyen" so the slider has a calm initial state and `Suivant`
    /// stays tappable without requiring a selection action.
    var energyLevel: Int = 2

    // Q3 — Priority (V11 voice-first; mirrors gratitude state)
    var priorityText: String = ""
    var priorityMicState: MicState = .idle
    var priorityEditingByKeyboard: Bool = false

    // Q4 — Gratitude
    var gratitudeText: String = ""
    var micState: MicState = .idle
    var editingByKeyboard: Bool = false

    private let startRitual: StartRitual
    private let saveAnswer: SaveQuestionnaireAnswer
    let dictation: DictateAnswer
    private var dictationTask: Task<Void, Never>?
    /// When non-nil, the upstream presence timer already created today's ritual
    /// and handed us its ID — `start()` then skips its redundant fetch and
    /// hydrates the existing `Ritual` snapshot instead.
    private let presetRitualId: UUID?

    init(
        startRitual: StartRitual,
        saveAnswer: SaveQuestionnaireAnswer,
        dictation: DictateAnswer,
        initialStep: QuestionnaireStep = .mood,
        presetRitualId: UUID? = nil
    ) {
        self.startRitual = startRitual
        self.saveAnswer = saveAnswer
        self.dictation = dictation
        self.step = initialStep
        self.presetRitualId = presetRitualId
        self.editingByKeyboard = !SettingsViewModel.isVoiceModeEnabled
    }

    // MARK: - Lifecycle

    func start() async {
        // `startRitual.execute()` calls `fetchOrCreateToday()` which is idempotent:
        // it returns the same ritual the presence timer already created (if any).
        // We always call it — `presetRitualId` is a hint we can verify against,
        // not a load-bearing parameter, so a stale hint can't desync state.
        do {
            ritual = try await startRitual.execute()
        } catch {
            // Ritual creation failed — surface gracefully if needed
        }
    }

    // MARK: - Step navigation

    var stepIndex: Int {
        switch step {
        case .mood:      return 0
        case .energy:    return 1
        case .priority:  return 2
        case .gratitude: return 3
        }
    }

    func advance() async throws {
        try await saveCurrent()
        switch step {
        case .mood:      step = .energy
        case .energy:    step = .priority
        case .priority:  step = .gratitude
        case .gratitude: break
        }
    }

    func goBack() {
        switch step {
        case .mood:      break
        case .energy:    step = .mood
        case .priority:  step = .energy
        case .gratitude: step = .priority
        }
    }

    // MARK: - Save current answer

    func saveCurrent() async throws {
        guard let ritual else { return }

        let payload: AnswerPayload
        switch step {
        case .mood:
            payload = .mood(level: moodLevel, tag: moodTag)
        case .energy:
            payload = .energy(level: EnergyLevel(sliderIndex: energyLevel))
        case .priority:
            let trimmed = priorityText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            payload = .priority(text: trimmed)
        case .gratitude:
            guard !gratitudeText.isEmpty else { return }
            payload = .gratitude(text: gratitudeText)
        }

        try await saveAnswer.execute(ritualId: ritual.id, payload: payload)
    }

    // MARK: - Dictation helpers

    func startDictation(for targetStep: QuestionnaireStep) {
        dictationTask?.cancel()
        // Explicit MainActor isolation — without it, the Task inherits the
        // enclosing context's isolation, which Swift 6 strict concurrency
        // can't always prove safe for cross-actor mutation inside the loop.
        dictationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let stream = self.dictation.execute(locale: Locale(identifier: "fr_FR"))
            for await state in stream {
                guard !Task.isCancelled else { break }
                self.handle(transcriptionState: state, for: targetStep)
            }
        }
    }

    func finishDictation(for targetStep: QuestionnaireStep) async {
        await dictation.finish()
        switch targetStep {
        case .gratitude:
            if micState == .listening {
                micState = gratitudeText.isEmpty ? .idle : .transcribed
            }
        case .priority:
            if priorityMicState == .listening {
                priorityMicState = priorityText.isEmpty ? .idle : .transcribed
            }
        default:
            break
        }
    }

    func cancelDictation(for targetStep: QuestionnaireStep) async {
        dictationTask?.cancel()
        dictationTask = nil
        await dictation.cancel()
        switch targetStep {
        case .gratitude:
            if micState == .listening {
                micState = .idle
            }
        case .priority:
            if priorityMicState == .listening {
                priorityMicState = .idle
            }
        default:
            break
        }
    }

    private func handle(transcriptionState: VoiceTranscribingState, for targetStep: QuestionnaireStep) {
        switch targetStep {
        case .gratitude:
            applyTranscriptionToGratitude(transcriptionState)
        case .priority:
            applyTranscriptionToPriority(transcriptionState)
        default:
            break
        }
    }

    private func applyTranscriptionToGratitude(_ state: VoiceTranscribingState) {
        switch state {
        case .listening:
            micState = .listening
        case .transcribed(let text):
            gratitudeText = text
            micState = .transcribed
        case .error(let err):
            if err.fallsBackToKeyboard { editingByKeyboard = true }
            micState = .idle
        case .finished:
            if micState == .listening {
                micState = gratitudeText.isEmpty ? .idle : .transcribed
            }
        }
    }

    private func applyTranscriptionToPriority(_ state: VoiceTranscribingState) {
        switch state {
        case .listening:
            priorityMicState = .listening
        case .transcribed(let text):
            priorityText = text
            priorityMicState = .transcribed
        case .error(let err):
            if err.fallsBackToKeyboard { priorityEditingByKeyboard = true }
            priorityMicState = .idle
        case .finished:
            if priorityMicState == .listening {
                priorityMicState = priorityText.isEmpty ? .idle : .transcribed
            }
        }
    }

    func resetGratitude() {
        dictationTask?.cancel()
        Task { await dictation.cancel() }
        gratitudeText = ""
        micState = .idle
    }

    func resetPriority() {
        dictationTask?.cancel()
        Task { await dictation.cancel() }
        priorityText = ""
        priorityMicState = .idle
    }
}

private extension VoiceTranscribingError {
    var fallsBackToKeyboard: Bool {
        switch self {
        case .permissionDenied, .unsupportedLocale, .audioEngineFailed:
            true
        case .recognitionFailed:
            false
        }
    }
}
