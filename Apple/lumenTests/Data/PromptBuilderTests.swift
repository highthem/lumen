// Copyright © 2026 Highthem. All rights reserved.
// Provided to PALO IT for evaluation purposes only.

import Testing
import Foundation
@testable import lumen

/// File-level helper: builds a Date from local Europe/Paris components.
/// Used as default parameter value in `sampleSleep` (can't reference Self.* methods there).
private func sleepDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
    var c = DateComponents()
    c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
    c.timeZone = TimeZone(identifier: "Europe/Paris")
    return Calendar(identifier: .gregorian).date(from: c)!
}

@Suite("PromptBuilder")
struct PromptBuilderTests {

    // MARK: - Helpers

    private func answer(_ payload: AnswerPayload) -> QuestionnaireAnswer {
        QuestionnaireAnswer(ritualId: UUID(), payload: payload)
    }

    private func sampleSleep(
        totalHours: Double = 7.2,
        deepHours: Double = 1.4,
        remHours: Double = 1.6,
        bedtime: Date = sleepDate(2026, 5, 8, 23, 45),
        wakeTime: Date = sleepDate(2026, 5, 9, 6, 57)
    ) -> SleepSummary {
        let total = totalHours * 3600
        let deep = deepHours * 3600
        let rem = remHours * 3600
        let core = max(0, total - deep - rem)
        return SleepSummary(
            bedtime: bedtime,
            wakeTime: wakeTime,
            totalAsleep: total,
            deep: deep,
            rem: rem,
            core: core,
            awake: 0
        )
    }

    // MARK: - User prompt: facts only

    @Test("Mood with tag uses tag, not /10 noise")
    func moodWithTag() {
        let (_, user) = PromptBuilder.build(answers: [answer(.mood(level: 7, tag: "posé"))])
        #expect(user.contains("humeur: posé"))
        #expect(!user.contains("/10"))
    }

    @Test("Mood without tag falls back to numeric level")
    func moodWithoutTag() {
        let (_, user) = PromptBuilder.build(answers: [answer(.mood(level: 6, tag: nil))])
        #expect(user.contains("humeur: niveau 6/10"))
    }

    @Test("Energy line includes displayName + magnitude (1..5)")
    func energyLine() {
        let (_, user) = PromptBuilder.build(answers: [answer(.energy(level: .charged))])
        #expect(user.contains("énergie: bien chargé"))
        #expect(user.contains("niveau 4 sur 5"))
    }

    @Test("Energy magnitude scales correctly across all levels")
    func energyAllLevels() {
        let cases: [(EnergyLevel, String, Int)] = [
            (.flat, "à plat", 1),
            (.low, "faiblard", 2),
            (.medium, "moyen", 3),
            (.charged, "bien chargé", 4),
            (.top, "au top", 5),
        ]
        for (level, name, magnitude) in cases {
            let (_, user) = PromptBuilder.build(answers: [answer(.energy(level: level))])
            #expect(user.contains("énergie: \(name) (niveau \(magnitude) sur 5)"))
        }
    }

    @Test("Priority text is trimmed; empty values skipped")
    func priorityTrimming() {
        let (_, withText) = PromptBuilder.build(answers: [answer(.priority(text: "  Bloquer 90 minutes.  "))])
        #expect(withText.contains("priorité: Bloquer 90 minutes."))
        #expect(!withText.contains("priorité:   "))

        let (_, empty) = PromptBuilder.build(answers: [answer(.priority(text: "   "))])
        #expect(!empty.contains("priorité:"))
    }

    @Test("Gratitude text is trimmed; empty values skipped")
    func gratitudeTrimming() {
        let (_, withText) = PromptBuilder.build(answers: [answer(.gratitude(text: "Le silence."))])
        #expect(withText.contains("gratitude: Le silence."))

        let (_, empty) = PromptBuilder.build(answers: [answer(.gratitude(text: ""))])
        #expect(!empty.contains("gratitude:"))
    }

    @Test("Answers ordering is preserved in user prompt")
    func answersOrder() {
        let (_, user) = PromptBuilder.build(answers: [
            answer(.mood(level: 7, tag: "posé")),
            answer(.energy(level: .medium)),
            answer(.priority(text: "Brief.")),
            answer(.gratitude(text: "Café.")),
        ])
        let lines = user.split(separator: "\n").map(String.init)
        #expect(lines.count == 4)
        #expect(lines[0].hasPrefix("humeur:"))
        #expect(lines[1].hasPrefix("énergie:"))
        #expect(lines[2].hasPrefix("priorité:"))
        #expect(lines[3].hasPrefix("gratitude:"))
    }

    // MARK: - Presence: factual only, no behavioral leak

    @Test("Presence completed is reported factually")
    func presenceCompleted() {
        let ctx = RitualContext(presence: .completed)
        let (_, user) = PromptBuilder.build(answers: [], context: ctx)
        #expect(user.contains("présence: completed"))
        // Behavioral instructions ("souligne", "invite", "reconnais") MUST live
        // in the system prompt, never in the user prompt — that's the refactor's invariant.
        #expect(!user.lowercased().contains("souligne"))
        #expect(!user.lowercased().contains("invite"))
        #expect(!user.lowercased().contains("reconnais"))
    }

    @Test("Presence partial / skipped are reported factually")
    func presenceOtherStates() {
        let (_, partial) = PromptBuilder.build(
            answers: [],
            context: RitualContext(presence: .partial)
        )
        #expect(partial.contains("présence: partial"))

        let (_, skipped) = PromptBuilder.build(
            answers: [],
            context: RitualContext(presence: .skipped)
        )
        #expect(skipped.contains("présence: skipped"))
    }

    @Test("Presence notStarted emits no presence line")
    func presenceNotStarted() {
        let (_, user) = PromptBuilder.build(
            answers: [answer(.gratitude(text: "x"))],
            context: RitualContext(presence: .notStarted)
        )
        #expect(!user.contains("présence:"))
    }

    // MARK: - Sleep: enriched signals

    @Test("Sleep nil emits no sleep line")
    func sleepAbsent() {
        let (_, user) = PromptBuilder.build(answers: [], context: RitualContext(sleep: nil))
        #expect(!user.contains("sommeil:"))
    }

    @Test("Sleep present emits hours, quality, bedtime, wakeTime")
    func sleepPresent() {
        let sleep = sampleSleep(totalHours: 7.2)
        let (_, user) = PromptBuilder.build(answers: [], context: RitualContext(sleep: sleep))
        #expect(user.contains("sommeil:"))
        #expect(user.contains("7.2h"))
        #expect(user.contains("qualité solide") || user.contains("qualité moyenne") || user.contains("qualité courte"))
        #expect(user.contains("couché 23h45"))
        #expect(user.contains("levé 06h57"))
    }

    @Test("Sleep flags low restorative ratio (deep+REM < 15%)")
    func sleepLowRestorative() {
        // 7h total, only 0.5h deep + 0.5h REM = 1h restorative / 7h = 14.3% < 15%
        let poor = sampleSleep(totalHours: 7.0, deepHours: 0.5, remHours: 0.5)
        let (_, user) = PromptBuilder.build(answers: [], context: RitualContext(sleep: poor))
        #expect(user.contains("peu de sommeil profond"))
    }

    @Test("Sleep does NOT flag when restorative ratio is healthy")
    func sleepHealthyRestorative() {
        // 7.2h total with 1.4h deep + 1.6h REM = 3h / 7.2h ≈ 41% — healthy
        let healthy = sampleSleep(totalHours: 7.2, deepHours: 1.4, remHours: 1.6)
        let (_, user) = PromptBuilder.build(answers: [], context: RitualContext(sleep: healthy))
        #expect(!user.contains("peu de sommeil profond"))
    }

    // MARK: - System prompt invariants

    @Test("System prompt declares imageKey, intention, focus, reminder, categoryInsights")
    func systemPromptSchema() {
        let s = PromptBuilder.systemPrompt
        for key in ["imageKey", "intention", "focus", "reminder", "categoryInsights"] {
            #expect(s.contains("`\(key)`") || s.contains("\"\(key)\""))
        }
    }

    @Test("System prompt declares oral / TTS constraints")
    func systemPromptOral() {
        let s = PromptBuilder.systemPrompt
        #expect(s.contains("VOIX HAUTE"))
        #expect(s.contains("markdown") || s.contains("Markdown"))
        #expect(s.contains("acronyme"))
    }

    @Test("System prompt declares anti-hallucination anchor")
    func systemPromptAnchor() {
        let s = PromptBuilder.systemPrompt
        #expect(s.contains("justifier"))
        #expect(s.contains("invent") || s.contains("ne l'invente"))
    }

    @Test("System prompt forbids hallucination of absent data")
    func anchorAntiHallucination() {
        let s = PromptBuilder.systemPrompt
        #expect(s.contains("ne mentionne pas") || s.contains("omets") || s.contains("Ne génère"))
        #expect(s.contains("invent") || s.contains("Inventer"))
    }

    @Test("System prompt declares correlation rules")
    func systemPromptCorrelation() {
        let s = PromptBuilder.systemPrompt
        #expect(s.contains("corrélation") || s.contains("Règles"))
        // Must mention at least these correlation pairs
        #expect(s.contains("énergie") && s.contains("sommeil"))
        #expect(s.contains("présence"))
    }

    @Test("System prompt declares anti-patterns explicitly")
    func antiPatterns() {
        let s = PromptBuilder.systemPrompt
        let crossCount = s.components(separatedBy: "❌").count - 1
        #expect(crossCount >= 3)
    }

    @Test("System prompt declares writing persona")
    func persona() {
        let s = PromptBuilder.systemPrompt
        #expect(s.contains("Annie Dillard") || s.contains("journal"))
        #expect(s.contains("miroir"))
    }

    @Test("System prompt provides at least one full input/output example")
    func fewShotExample() {
        let s = PromptBuilder.systemPrompt
        #expect(s.contains("Input utilisateur") || s.contains("Output attendu"))
        #expect(s.contains("\"imageKey\""))
        #expect(s.contains("\"focus\""))
    }

    @Test("System prompt keeps the long quality bar and examples")
    func systemPromptLengthAndQualityBar() {
        let s = PromptBuilder.systemPrompt
        #expect(s.count >= 3_500)
        #expect(s.contains("Quality bar"))
        #expect(s.contains("Exemple 1"))
        #expect(s.contains("Exemple 2"))
        #expect(s.contains("Tension entre signaux"))
    }

    // MARK: - Hash stability

    @Test("Hash is stable for identical inputs")
    func hashStability() {
        let answers = [
            answer(.mood(level: 7, tag: "posé")),
            answer(.gratitude(text: "Café.")),
        ]
        let ctx = RitualContext(presence: .completed, sleep: sampleSleep())
        let (s1, u1) = PromptBuilder.build(answers: answers, context: ctx)
        let (s2, u2) = PromptBuilder.build(answers: answers, context: ctx)
        #expect(PromptBuilder.hash(system: s1, user: u1) == PromptBuilder.hash(system: s2, user: u2))
    }

    @Test("Hash differs when user input differs")
    func hashDiffers() {
        let (s, u1) = PromptBuilder.build(answers: [answer(.gratitude(text: "Café."))])
        let (_, u2) = PromptBuilder.build(answers: [answer(.gratitude(text: "Thé."))])
        #expect(PromptBuilder.hash(system: s, user: u1) != PromptBuilder.hash(system: s, user: u2))
    }

    @Test("Hash is hex-encoded SHA-256 (64 chars)")
    func hashFormat() {
        let h = PromptBuilder.hash(system: "a", user: "b")
        #expect(h.count == 64)
        #expect(h.allSatisfy { $0.isHexDigit })
    }
}
