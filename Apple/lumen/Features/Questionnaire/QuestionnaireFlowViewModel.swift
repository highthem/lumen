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
    var energyLevel: EnergyLevel?

    // Q3 — Priority
    var priorityCategory: PriorityCategory?
    var priorityNote: String = ""

    // Q4 — Gratitude
    var gratitudeText: String = ""
    var micState: MicState = .idle
    var editingByKeyboard: Bool = false

    private let startRitual: StartRitual
    private let saveAnswer: SaveQuestionnaireAnswer
    let dictation: DictateAnswer
    private var dictationTask: Task<Void, Never>?

    init(
        startRitual: StartRitual,
        saveAnswer: SaveQuestionnaireAnswer,
        dictation: DictateAnswer,
        initialStep: QuestionnaireStep = .mood
    ) {
        self.startRitual = startRitual
        self.saveAnswer = saveAnswer
        self.dictation = dictation
        self.step = initialStep
        self.editingByKeyboard = !SettingsViewModel.isVoiceModeEnabled
    }

    // MARK: - Lifecycle

    func start() async {
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
            guard let level = energyLevel else { return }
            payload = .energy(level: level)
        case .priority:
            guard let category = priorityCategory else { return }
            payload = .priority(category: category, note: priorityNote.isEmpty ? nil : priorityNote)
        case .gratitude:
            guard !gratitudeText.isEmpty else { return }
            payload = .gratitude(text: gratitudeText)
        }

        try await saveAnswer.execute(ritualId: ritual.id, payload: payload)
    }

    // MARK: - Dictation helpers

    func startDictation(for targetStep: QuestionnaireStep) {
        dictationTask?.cancel()
        dictationTask = Task {
            let stream = dictation.execute(locale: Locale(identifier: "fr_FR"))
            for await state in stream {
                guard !Task.isCancelled else { break }
                handle(transcriptionState: state, for: targetStep)
            }
        }
    }

    func stopDictation(for targetStep: QuestionnaireStep) async {
        dictationTask?.cancel()
        await dictation.stop()
        switch targetStep {
        case .gratitude:
            if micState == .listening { micState = gratitudeText.isEmpty ? .idle : .transcribed }
        default:
            break
        }
    }

    private func handle(transcriptionState: VoiceTranscribingState, for targetStep: QuestionnaireStep) {
        switch targetStep {
        case .gratitude:
            switch transcriptionState {
            case .listening:
                micState = .listening
            case .transcribed(let text):
                gratitudeText = text
                micState = .transcribed
            case .error(let err):
                if err == .unsupportedLocale || err == .permissionDenied { editingByKeyboard = true }
                micState = .idle
            case .finished:
                if micState == .listening { micState = gratitudeText.isEmpty ? .idle : .transcribed }
            }
        default:
            break
        }
    }

    func resetGratitude() {
        dictationTask?.cancel()
        gratitudeText = ""
        micState = .idle
    }
}
