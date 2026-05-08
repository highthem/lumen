import Testing
@testable import lumen

@Suite("Lumen diagnostic logging")
struct LumenDiagnosticLoggerTests {

    @Test("Log categories use the app subsystem")
    func categoriesUseAppSubsystem() {
        #expect(LumenLog.app.subsystem == "com.highthem.lumen")
        #expect(LumenLog.persistence.subsystem == "com.highthem.lumen")
        #expect(LumenLog.ai.subsystem == "com.highthem.lumen")
        #expect(LumenLog.network.subsystem == "com.highthem.lumen")
        #expect(LumenLog.notifications.subsystem == "com.highthem.lumen")
        #expect(LumenLog.audio.subsystem == "com.highthem.lumen")
        #expect(LumenLog.speechRecognition.subsystem == "com.highthem.lumen")
        #expect(LumenLog.textToSpeech.subsystem == "com.highthem.lumen")
    }

    @Test("Log categories are stable and human readable")
    func categoriesAreStable() {
        #expect(LumenLog.app.category == "app")
        #expect(LumenLog.persistence.category == "persistence")
        #expect(LumenLog.ai.category == "ai")
        #expect(LumenLog.network.category == "network")
        #expect(LumenLog.notifications.category == "notifications")
        #expect(LumenLog.audio.category == "audio")
        #expect(LumenLog.speechRecognition.category == "speech-recognition")
        #expect(LumenLog.textToSpeech.category == "text-to-speech")
    }

    @Test("Error descriptions are concise")
    func errorDescriptionsAreConcise() {
        #expect(LumenLog.ai.describe(error: SampleError.missingKey) == "missingKey")
    }

    private enum SampleError: Error {
        case missingKey
    }
}
