import Foundation

struct ContentSafetyDetector: Sendable {

    nonisolated func detect(in text: String) -> [ContentSafetyFlag] {
        let lower = text.lowercased()
        var flags: Set<ContentSafetyFlag> = []

        let selfHarmKeywords = [
            // FR
            "suicide", "me tuer", "me suicider", "en finir", "me faire du mal",
            // EN
            "kill myself", "end my life", "ending my life", "harm myself", "self-harm"
        ]
        if selfHarmKeywords.contains(where: { lower.contains($0) }) {
            flags.insert(.selfHarmCue)
        }

        let violentKeywords = [
            // FR
            "tuer", "frapper",
            // EN
            "kill", "shoot", "stab"
        ]
        if violentKeywords.contains(where: { lower.contains($0) }) {
            flags.insert(.violentLanguage)
        }

        let medicalKeywords = [
            // FR
            "diagnostiquer", "diagnostic médical",
            // EN
            "diagnose", "medical advice"
        ]
        if medicalKeywords.contains(where: { lower.contains($0) }) {
            flags.insert(.medicalAdviceRequest)
        }

        let legalKeywords = [
            // FR
            "poursuivre en justice",
            // EN
            "lawsuit", "sue them"
        ]
        if legalKeywords.contains(where: { lower.contains($0) }) {
            flags.insert(.legalAdviceRequest)
        }

        return Array(flags)
    }
}
