import Foundation

struct SpeakSynthesis: Sendable {
    private let tts: any TextToSpeeching

    init(tts: any TextToSpeeching) {
        self.tts = tts
    }

    func execute(response: AIResponse, voiceId: String? = nil, rate: Double = 1.0) async throws {
        let text = [response.intention, response.focus.joined(separator: ". "), response.reminder]
            .joined(separator: "\n\n")
        try await tts.speak(text, voiceId: voiceId, rate: rate)
    }

    /// Pass-through to the underlying TTS impl. The view subscribes BEFORE
    /// calling `execute(...)` so it doesn't miss the first emit.
    @MainActor
    func progress() -> AsyncStream<TTSProgress> {
        tts.progress()
    }

    @MainActor
    func stop() {
        tts.stop()
    }
}
