import XCTest
@testable import lumen

@MainActor
final class ContentSafetyDetectorTests: XCTestCase {

    private let sut = ContentSafetyDetector()

    // MARK: - Self-harm detection

    func testFRSelfHarmCue_suicide() {
        let flags = sut.detect(in: "Je pense au suicide")
        XCTAssertTrue(flags.contains(.selfHarmCue))
    }

    func testFRSelfHarmCue_meTuer() {
        let flags = sut.detect(in: "J'ai envie de me tuer aujourd'hui")
        XCTAssertTrue(flags.contains(.selfHarmCue))
    }

    func testFRSelfHarmCue_enFinir() {
        let flags = sut.detect(in: "Je veux en finir avec tout")
        XCTAssertTrue(flags.contains(.selfHarmCue))
    }

    func testENSelfHarmCue_killMyself() {
        let flags = sut.detect(in: "I want to kill myself")
        XCTAssertTrue(flags.contains(.selfHarmCue))
    }

    func testENSelfHarmCue_endMyLife() {
        let flags = sut.detect(in: "thinking about ending my life")
        XCTAssertTrue(flags.contains(.selfHarmCue))
    }

    func testENSelfHarmCue_harmMyself() {
        let flags = sut.detect(in: "urge to harm myself")
        XCTAssertTrue(flags.contains(.selfHarmCue))
    }

    // MARK: - Case insensitive

    func testCaseInsensitive() {
        let flags = sut.detect(in: "KILL MYSELF")
        XCTAssertTrue(flags.contains(.selfHarmCue))
    }

    // MARK: - Violent language

    func testENViolentLanguage_shoot() {
        let flags = sut.detect(in: "I want to shoot someone")
        XCTAssertTrue(flags.contains(.violentLanguage))
    }

    func testFRViolentLanguage_frapper() {
        let flags = sut.detect(in: "j'ai envie de frapper mon patron")
        XCTAssertTrue(flags.contains(.violentLanguage))
    }

    // MARK: - Medical advice

    func testMedicalAdvice_EN() {
        let flags = sut.detect(in: "can you diagnose my symptoms")
        XCTAssertTrue(flags.contains(.medicalAdviceRequest))
    }

    func testMedicalAdvice_FR() {
        let flags = sut.detect(in: "besoin d'un diagnostic médical")
        XCTAssertTrue(flags.contains(.medicalAdviceRequest))
    }

    // MARK: - Legal advice

    func testLegalAdvice_EN() {
        let flags = sut.detect(in: "I want to sue them for everything")
        XCTAssertTrue(flags.contains(.legalAdviceRequest))
    }

    func testLegalAdvice_FR() {
        let flags = sut.detect(in: "je vais poursuivre en justice cette entreprise")
        XCTAssertTrue(flags.contains(.legalAdviceRequest))
    }

    // MARK: - Benign text returns empty

    func testBenignText_morning() {
        let flags = sut.detect(in: "Je me sens bien ce matin, plein d'énergie")
        XCTAssertTrue(flags.isEmpty)
    }

    func testBenignText_gratitude() {
        let flags = sut.detect(in: "I am grateful for my family and friends")
        XCTAssertTrue(flags.isEmpty)
    }

    func testBenignText_empty() {
        let flags = sut.detect(in: "")
        XCTAssertTrue(flags.isEmpty)
    }

    // MARK: - Multiple flags in one text

    func testMultipleFlagsDetected() {
        let flags = sut.detect(in: "I want to kill myself and I need medical advice to diagnose this")
        XCTAssertTrue(flags.contains(.selfHarmCue))
        XCTAssertTrue(flags.contains(.medicalAdviceRequest))
    }

    // MARK: - Distinct flags (no duplicates)

    func testDistinctFlags() {
        let flags = sut.detect(in: "suicide suicide suicide")
        let selfHarmCount = flags.filter { $0 == .selfHarmCue }.count
        XCTAssertEqual(selfHarmCount, 1, "Should not return duplicate flags")
    }
}
