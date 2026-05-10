import Testing
@testable import lumen

@Suite("ContentSafetyDetector")
@MainActor
struct ContentSafetyDetectorTests {

    private let sut = ContentSafetyDetector()

    // MARK: - Self-harm detection (parametric)

    @Test(
        "detects selfHarmCue in flagged inputs",
        arguments: [
            "Je pense au suicide",
            "J'ai envie de me tuer aujourd'hui",
            "Je veux en finir avec tout",
            "I want to kill myself",
            "thinking about ending my life",
            "urge to harm myself",
            "KILL MYSELF",          // case insensitive
        ]
    )
    func detectsSelfHarmCue(input: String) {
        let flags = sut.detect(in: input)
        #expect(flags.contains(.selfHarmCue))
    }

    // MARK: - Violent language (parametric)

    @Test(
        "detects violentLanguage in flagged inputs",
        arguments: [
            "I want to shoot someone",
            "j'ai envie de frapper mon patron",
        ]
    )
    func detectsViolentLanguage(input: String) {
        let flags = sut.detect(in: input)
        #expect(flags.contains(.violentLanguage))
    }

    // MARK: - Medical advice (parametric)

    @Test(
        "detects medicalAdviceRequest in flagged inputs",
        arguments: [
            "can you diagnose my symptoms",
            "besoin d'un diagnostic médical",
        ]
    )
    func detectsMedicalAdvice(input: String) {
        let flags = sut.detect(in: input)
        #expect(flags.contains(.medicalAdviceRequest))
    }

    // MARK: - Legal advice (parametric)

    @Test(
        "detects legalAdviceRequest in flagged inputs",
        arguments: [
            "I want to sue them for everything",
            "je vais poursuivre en justice cette entreprise",
        ]
    )
    func detectsLegalAdvice(input: String) {
        let flags = sut.detect(in: input)
        #expect(flags.contains(.legalAdviceRequest))
    }

    // MARK: - Benign text returns empty (parametric)

    @Test(
        "benign text returns empty flags",
        arguments: [
            "Je me sens bien ce matin, plein d'énergie",
            "I am grateful for my family and friends",
            "",
        ]
    )
    func benignTextReturnsEmpty(input: String) {
        let flags = sut.detect(in: input)
        #expect(flags.isEmpty)
    }

    // MARK: - Multiple flags in one text

    @Test("multiple flags are detected in a single text")
    func multipleFlagsDetected() {
        let flags = sut.detect(in: "I want to kill myself and I need medical advice to diagnose this")
        #expect(flags.contains(.selfHarmCue))
        #expect(flags.contains(.medicalAdviceRequest))
    }

    // MARK: - Distinct flags (no duplicates)

    @Test("repeated trigger words do not produce duplicate flags")
    func distinctFlags() {
        let flags = sut.detect(in: "suicide suicide suicide")
        let selfHarmCount = flags.filter { $0 == .selfHarmCue }.count
        #expect(selfHarmCount == 1)
    }
}
