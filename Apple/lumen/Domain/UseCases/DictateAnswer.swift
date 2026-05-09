import Foundation

struct DictateAnswer: Sendable {
    private let transcriber: any VoiceTranscribing

    init(transcriber: any VoiceTranscribing) {
        self.transcriber = transcriber
    }

    func execute(locale: Locale) -> AsyncStream<VoiceTranscribingState> {
        transcriber.startTranscription(locale: locale)
    }

    func finish() async {
        await transcriber.finishTranscription()
    }

    func cancel() async {
        await transcriber.cancelTranscription()
    }
}
