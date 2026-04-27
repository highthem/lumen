import Foundation

struct SpeakSynthesis: Sendable {
    private let tts: any TextToSpeeching

    init(tts: any TextToSpeeching) {
        self.tts = tts
    }

    func execute(response: AIResponse, voiceId: String? = nil, rate: Double = 1.0) async {
        let text = [response.intention, response.focus.joined(separator: ". "), response.reminder]
            .joined(separator: "\n\n")
        await tts.speak(text, voiceId: voiceId, rate: rate)
    }

    func stop() {
        tts.stop()
    }
}
