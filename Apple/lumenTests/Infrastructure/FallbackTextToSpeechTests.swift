import Testing
import Foundation
@testable import lumen

@Suite("FallbackTextToSpeech")
struct FallbackTextToSpeechTests {

    final class StubTTS: TextToSpeeching, @unchecked Sendable {
        var shouldThrow: Error?
        var speakInvocations = 0
        var lastText: String?
        var isSpeaking = false

        func speak(_ text: String, voiceId: String?, rate: Double) async throws {
            speakInvocations += 1
            lastText = text
            if let e = shouldThrow { throw e }
        }
        func pause() {}
        func resume() {}
        func stop() {}
        func availableVoices() -> [TTSVoice] { [] }
    }

    @Test("Primary OK — fallback never called")
    func primaryOk() async throws {
        let primary = StubTTS()
        let fallback = StubTTS()
        let sut = FallbackTextToSpeech(primary: primary, fallback: fallback)

        try await sut.speak("hello", voiceId: nil, rate: 1.0)

        #expect(primary.speakInvocations == 1)
        #expect(fallback.speakInvocations == 0)
    }

    @Test("Primary throws — fallback takes over and succeeds")
    func primaryThrows() async throws {
        let primary = StubTTS()
        primary.shouldThrow = ElevenLabsError.timeout
        let fallback = StubTTS()
        let sut = FallbackTextToSpeech(primary: primary, fallback: fallback)

        try await sut.speak("hello", voiceId: nil, rate: 1.0)

        #expect(primary.speakInvocations == 1)
        #expect(fallback.speakInvocations == 1)
        #expect(fallback.lastText == "hello")
    }

    @Test("Primary and fallback both throw — error propagates")
    func bothThrow() async throws {
        struct AVErr: Error {}
        let primary = StubTTS()
        primary.shouldThrow = ElevenLabsError.invalidKey
        let fallback = StubTTS()
        fallback.shouldThrow = AVErr()
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

        // Call 1 : primary OK
        try await sut.speak("first", voiceId: nil, rate: 1.0)
        // Call 2 : primary throws
        primary.shouldThrow = ElevenLabsError.quotaExceeded
        try await sut.speak("second", voiceId: nil, rate: 1.0)
        // Call 3 : primary back online
        primary.shouldThrow = nil
        try await sut.speak("third", voiceId: nil, rate: 1.0)

        #expect(primary.speakInvocations == 3)
        #expect(fallback.speakInvocations == 1)
        #expect(fallback.lastText == "second")
    }
}
