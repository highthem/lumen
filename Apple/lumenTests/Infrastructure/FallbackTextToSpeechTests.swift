import Testing
import Foundation
@testable import lumen

@Suite("FallbackTextToSpeech")
struct FallbackTextToSpeechTests {

    actor StubTTS: TextToSpeeching {
        var shouldThrow: Error?
        private(set) var speakInvocations = 0
        private(set) var lastText: String?
        private(set) var isSpeaking = false

        func setShouldThrow(_ error: Error?) { shouldThrow = error }

        func speak(_ text: String, voiceId: String?, rate: Double) async throws {
            speakInvocations += 1
            lastText = text
            if let e = shouldThrow { throw e }
        }
        func pause()  {}
        func resume() {}
        func stop()   {}
        func availableVoices() -> [TTSVoice] { [] }
    }

    @Test("Primary OK — fallback never called")
    func primaryOk() async throws {
        let primary = StubTTS()
        let fallback = StubTTS()
        let sut = FallbackTextToSpeech(primary: primary, fallback: fallback)

        try await sut.speak("hello", voiceId: nil, rate: 1.0)

        let primaryCount = await primary.speakInvocations
        let fallbackCount = await fallback.speakInvocations
        #expect(primaryCount == 1)
        #expect(fallbackCount == 0)
    }

    @Test("Primary throws — fallback takes over and succeeds")
    func primaryThrows() async throws {
        let primary = StubTTS()
        await primary.setShouldThrow(ElevenLabsError.timeout)
        let fallback = StubTTS()
        let sut = FallbackTextToSpeech(primary: primary, fallback: fallback)

        try await sut.speak("hello", voiceId: nil, rate: 1.0)

        let primaryCount = await primary.speakInvocations
        let fallbackCount = await fallback.speakInvocations
        let fallbackText = await fallback.lastText
        #expect(primaryCount == 1)
        #expect(fallbackCount == 1)
        #expect(fallbackText == "hello")
    }

    @Test("Primary and fallback both throw — error propagates")
    func bothThrow() async throws {
        struct AVErr: Error {}
        let primary = StubTTS()
        await primary.setShouldThrow(ElevenLabsError.invalidKey)
        let fallback = StubTTS()
        await fallback.setShouldThrow(AVErr())
        let sut = FallbackTextToSpeech(primary: primary, fallback: fallback)

        await #expect(throws: AVErr.self) {
            try await sut.speak("hello", voiceId: nil, rate: 1.0)
        }
    }

    @Test("Each call resolves routing independently — flaky primary")
    func independentRouting() async throws {
        let primary = StubTTS()
        let fallback = StubTTS()
        let sut = FallbackTextToSpeech(primary: primary, fallback: fallback)

        // Call 1: primary OK
        try await sut.speak("first", voiceId: nil, rate: 1.0)
        // Call 2: primary throws
        await primary.setShouldThrow(ElevenLabsError.quotaExceeded)
        try await sut.speak("second", voiceId: nil, rate: 1.0)
        // Call 3: primary back online
        await primary.setShouldThrow(nil)
        try await sut.speak("third", voiceId: nil, rate: 1.0)

        let primaryCount = await primary.speakInvocations
        let fallbackCount = await fallback.speakInvocations
        let fallbackText = await fallback.lastText
        #expect(primaryCount == 3)
        #expect(fallbackCount == 1)
        #expect(fallbackText == "second")
    }
}
