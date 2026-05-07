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

    // Q2 — Priority
    var priorityCategory: DashboardCategory?
    var priorityNote: String = ""

    // Q3 — Gratitude
    var gratitudeText: String = ""
    var micState: MicState = .idle
    var editingByKeyboard: Bool = false

    // Q4 — Intention
    var intentionWord: String = ""
    var intentionMicState: MicState = .idle
    var intentionEditingByKeyboard: Bool = false

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
        self.intentionEditingByKeyboard = !SettingsViewModel.isVoiceModeEnabled
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
        case .mood:       return 0
        case .priority:   return 1
        case .gratitude:  return 2
        case .intention:  return 3
        }
    }

    func advance() async throws {
        try await saveCurrent()
        switch step {
        case .mood:      step = .priority
        case .priority:  step = .gratitude
        case .gratitude: step = .intention
        case .intention: break
        }
    }

    func goBack() {
        switch step {
        case .mood:       break
        case .priority:   step = .mood
        case .gratitude:  step = .priority
        case .intention:  step = .gratitude
        }
    }

    // MARK: - Save current answer

    func saveCurrent() async throws {
        guard let ritual else { return }

        let payload: AnswerPayload
        switch step {
        case .mood:
            payload = .mood(level: moodLevel, tag: moodTag)
        case .priority:
            guard let category = priorityCategory else { return }
            payload = .priority(category: category, note: priorityNote.isEmpty ? nil : priorityNote)
        case .gratitude:
            guard !gratitudeText.isEmpty else { return }
            payload = .gratitude(text: gratitudeText)
        case .intention:
            guard !intentionWord.isEmpty else { return }
            payload = .intention(word: intentionWord)
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
        case .intention:
            if intentionMicState == .listening { intentionMicState = intentionWord.isEmpty ? .idle : .transcribed }
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
        case .intention:
            switch transcriptionState {
            case .listening:
                intentionMicState = .listening
            case .transcribed(let text):
                intentionWord = text
                intentionMicState = .transcribed
            case .error(let err):
                if err == .unsupportedLocale || err == .permissionDenied { intentionEditingByKeyboard = true }
                intentionMicState = .idle
            case .finished:
                if intentionMicState == .listening { intentionMicState = intentionWord.isEmpty ? .idle : .transcribed }
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

    func resetIntention() {
        dictationTask?.cancel()
        intentionWord = ""
        intentionMicState = .idle
    }
}
