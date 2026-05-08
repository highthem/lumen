#if DEBUG
import Foundation
import SwiftData

@MainActor
@Observable
final class MaestroTestState {
    enum SynthesisRouteState: Sendable {
        case ready
        case queued
        case rateLimited
    }

    var synthesisState: SynthesisRouteState = .ready
    var voicePermissionDenied = false

    func response(for ritualId: UUID, mode: AIResponseMode) -> AIResponse {
        AIResponse(
            ritualId: ritualId,
            intention: "présence",
            focus: ["Garde une priorité simple.", "Laisse de la place au corps."],
            reminder: "Reviens à ton souffle avant de répondre.",
            provider: .openai,
            mode: mode
        )
    }
}

enum MaestroRoute {
    case dashboard(state: DashboardState)
    case timer
    case questionnaire(step: QuestionnaireStep)
    case synthesis(ritualId: UUID)
    case alarmRinging(alarmId: UUID)

    enum DashboardState {
        case empty
        case alarm
        case ritual
    }
}

@MainActor
enum MaestroTestSupport {
    static func route(
        for url: URL,
        composition: CompositionRoot,
        state: MaestroTestState
    ) async -> MaestroRoute? {
        guard url.scheme == "lumen" else { return nil }

        switch (url.host ?? "", normalizedPath(url)) {
        case ("test", "/dashboard"):
            let requested = queryValue("state", in: url) ?? "alarm"
            let routeState = MaestroRoute.DashboardState(rawValue: requested)
            await resetAppState(composition: composition)
            OnboardingFlag.markCompleted()
            UserDefaults.standard.set(routeState == .ritual, forKey: "lumen.hasAnyRitual")
            if routeState != .empty {
                _ = try? await seedAlarm(composition: composition)
            }
            if routeState == .ritual {
                _ = try? await seedRitual(upTo: .gratitude, composition: composition)
            }
            return .dashboard(state: routeState)

        case ("ritual", "/start"), ("ritual", "/timer"):
            OnboardingFlag.markCompleted()
            _ = try? await seedAlarm(composition: composition)
            return .timer

        case ("ritual", "/q2"):
            // Legacy route — pre-V11, "Q2" was Priority. Kept for any
            // older Maestro flows still pointing here.
            OnboardingFlag.markCompleted()
            _ = try? await seedRitual(upTo: .mood, composition: composition)
            return .questionnaire(step: .priority)

        case ("ritual", "/q2-energy"):
            // V11 route — opens the new breathing-orb + slider directly.
            OnboardingFlag.markCompleted()
            _ = try? await seedRitual(upTo: .mood, composition: composition)
            return .questionnaire(step: .energy)

        case ("ritual", "/q3"):
            OnboardingFlag.markCompleted()
            state.voicePermissionDenied = queryValue("mic", in: url) == "denied"
            _ = try? await seedRitual(upTo: .priority, composition: composition)
            return .questionnaire(step: .gratitude)

        case ("ritual", "/q4-direct"):
            OnboardingFlag.markCompleted()
            _ = try? await seedRitual(upTo: .priority, composition: composition)
            return .questionnaire(step: .gratitude)

        case ("ritual", "/synthesis-mock"):
            OnboardingFlag.markCompleted()
            state.synthesisState = .ready
            let ritualId = (try? await seedRitual(upTo: .gratitude, composition: composition)) ?? UUID()
            return .synthesis(ritualId: ritualId)

        case ("test", "/synthesis"):
            OnboardingFlag.markCompleted()
            state.synthesisState = synthesisState(from: queryValue("state", in: url))
            let ritualId = (try? await seedRitual(upTo: .gratitude, composition: composition)) ?? UUID()
            return .synthesis(ritualId: ritualId)

        case ("alarm", "/test-ringing"):
            OnboardingFlag.markCompleted()
            let alarm = try? await seedAlarm(composition: composition)
            let id = alarm?.id ?? UUID()
            await composition.appStateMachine.send(.alarmFired(alarmId: id))
            return .alarmRinging(alarmId: id)

        default:
            return nil
        }
    }

    private static func normalizedPath(_ url: URL) -> String {
        let path = url.path
        return path.isEmpty ? "/" : path
    }

    private static func queryValue(_ name: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }

    private static func synthesisState(from value: String?) -> MaestroTestState.SynthesisRouteState {
        switch value {
        case "queued": return .queued
        case "rateLimited": return .rateLimited
        default: return .ready
        }
    }

    private static func resetAppState(composition: CompositionRoot) async {
        await composition.appStateMachine.send(.reset)
        await composition.rateLimiter.reset()
    }

    @discardableResult
    private static func seedAlarm(composition: CompositionRoot) async throws -> Alarm {
        if let existing = try await composition.alarmRepository.all().first {
            return existing
        }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        components.second = 0
        let date = Calendar.current.date(from: components) ?? Date()
        let alarm = Alarm(time: date, recurrence: .weekdays, soundId: "alarm-aube")
        try await composition.alarmRepository.save(alarm)
        return alarm
    }

    @discardableResult
    private static func seedRitual(upTo step: QuestionnaireStep, composition: CompositionRoot) async throws -> UUID {
        let ritual = try await composition.ritualRepository.fetchOrCreateToday()
        let existing = Set(ritual.answers.map(\.step))
        let payloads = payloads(upTo: step)
        for payload in payloads where !existing.contains(payload.step) {
            try await composition.saveQuestionnaireAnswer.execute(ritualId: ritual.id, payload: payload)
        }
        if step == .gratitude {
            UserDefaults.standard.set(true, forKey: "lumen.hasAnyRitual")
        }
        return ritual.id
    }

    private static func payloads(upTo step: QuestionnaireStep) -> [AnswerPayload] {
        let all: [(QuestionnaireStep, AnswerPayload)] = [
            (.mood, .mood(level: 2, tag: "posé")),
            (.energy, .energy(level: .medium)),
            (.priority, .priority(text: "Bloquer 90 minutes pour le brief.")),
            (.gratitude, .gratitude(text: "Le silence avant que les enfants se lèvent."))
        ]
        guard let index = all.firstIndex(where: { $0.0 == step }) else { return [] }
        return all.prefix(index + 1).map(\.1)
    }
}

extension MaestroRoute.DashboardState {
    init(rawValue: String) {
        switch rawValue {
        case "empty": self = .empty
        case "ritual": self = .ritual
        default: self = .alarm
        }
    }
}

struct MaestroAlarmScheduler: AlarmScheduling {
    func requestAuthorizationIfNeeded() async throws -> Bool { false }
    func schedule(_ alarm: Alarm) async throws {}
    func cancel(id: UUID) async throws {}
    func cancelAll() async throws {}
    func snooze(_ alarm: Alarm, minutes: Int) async throws {}
}

@MainActor
final class MaestroAudioPlayer: AudioPlaying {
    func configureSession() async throws {}
    func play(soundId: String, fadeIn: Bool) async throws {}
    func stop() {}
    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {}
}

@MainActor
final class MaestroTextToSpeech: TextToSpeeching {
    private(set) var isSpeaking: Bool = false
    func availableVoices() -> [TTSVoice] {
        [TTSVoice(id: "maestro-fr", name: "Maestro FR", lang: "fr-FR", quality: .default)]
    }
    func speak(_ text: String, voiceId: String?, rate: Double) async throws {
        isSpeaking = true
        try? await Task.sleep(for: .milliseconds(250))
        isSpeaking = false
    }
    func progress() -> AsyncStream<TTSProgress> {
        AsyncStream { cont in
            // Maestro TTS is fire-and-forget — emit a single full-duration
            // tick so the listen-player UI doesn't sit at 0% during tests.
            cont.yield(TTSProgress(elapsedSeconds: 0, totalSeconds: 1))
            cont.finish()
        }
    }
    func pause() { isSpeaking = false }
    func resume() { isSpeaking = true }
    func stop()   { isSpeaking = false }
}

final class MaestroVoiceTranscriber: VoiceTranscribing {
    func startTranscription(locale: Locale) -> AsyncStream<VoiceTranscribingState> {
        AsyncStream { continuation in
            continuation.yield(.error(.permissionDenied))
            continuation.finish()
        }
    }

    func stop() async {}
    func isOnDeviceSupported(locale: Locale) -> Bool { true }
}

@MainActor
final class MaestroAISynthesisService: AISynthesisService {
    private let testState: MaestroTestState

    init(testState: MaestroTestState) {
        self.testState = testState
    }

    nonisolated func synthesize(
        answers: [QuestionnaireAnswer],
        ritualId: UUID,
        mode: AIResponseMode,
        context: RitualContext
    ) async throws -> AIResponseResult {
        let route = await self.testState.synthesisState
        switch route {
        case .ready:
            let response = await self.testState.response(for: ritualId, mode: mode)
            return .ready(response)
        case .queued:
            return .queued(estimatedDelivery: nil)
        case .rateLimited:
            throw AIError.rateLimited
        }
    }
}
#endif
