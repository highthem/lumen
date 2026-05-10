import Foundation
import Testing
@testable import lumen

@Suite("AIResponse generated JSON decoding")
struct AIResponseTests {

    @Test("AIResponse decodes JSON with imageKey + categoryInsights")
    func decodeFullResponse() throws {
        let json = """
        {
          "imageKey": "matin tenu",
          "intention": "Tu poses la journée dans le silence.",
          "focus": ["Commence par le brief.", "Garde une heure protégée."],
          "reminder": "Le silence tient encore.",
          "categoryInsights": {
            "mood": "Posé. Une bonne assise.",
            "energy": "Faiblard. Préserve.",
            "sleep": "Six heures. Assez pour tenir."
          }
        }
        """

        let response = try AIResponse.decodeGeneratedJSON(
            Data(json.utf8),
            ritualId: UUID(),
            provider: .openai,
            mode: .auto
        )

        #expect(response.imageKey == "matin tenu")
        #expect(response.intention == "Tu poses la journée dans le silence.")
        #expect(response.focus.count == 2)
        #expect(response.reminder == "Le silence tient encore.")
        #expect(response.categoryInsights?[.mood] == "Posé. Une bonne assise.")
        #expect(response.categoryInsights?[.energy] == "Faiblard. Préserve.")
        #expect(response.categoryInsights?[.sleep] == "Six heures. Assez pour tenir.")
    }

    @Test("AIResponse decodes legacy JSON without imageKey")
    func decodeLegacyNoImageKey() throws {
        let json = """
        {
          "intention": "Tu gardes une priorité simple.",
          "focus": ["Écris la première ligne."],
          "reminder": "Reviens au souffle."
        }
        """

        let response = try AIResponse.decodeGeneratedJSON(
            Data(json.utf8),
            ritualId: UUID(),
            provider: .anthropic,
            mode: .manualRegenerate
        )

        #expect(response.imageKey == nil)
        #expect(response.categoryInsights == nil)
        #expect(response.intention == "Tu gardes une priorité simple.")
    }

    @Test("AIResponse decodes JSON with empty imageKey as nil")
    func decodeEmptyImageKey() throws {
        let json = """
        {
          "imageKey": "   ",
          "intention": "Tu gardes le cap.",
          "focus": ["Pose une limite."],
          "reminder": "",
          "categoryInsights": {
            "mood": "",
            "priority": "Le brief mérite ton meilleur créneau."
          }
        }
        """

        let response = try AIResponse.decodeGeneratedJSON(
            Data(json.utf8),
            ritualId: UUID(),
            provider: .openai,
            mode: .auto
        )

        #expect(response.imageKey == nil)
        #expect(response.reminder == "")
        #expect(response.categoryInsights?[.mood] == nil)
        #expect(response.categoryInsights?[.priority] == "Le brief mérite ton meilleur créneau.")
    }

    @Test("AIResponse ignores unknown categoryInsights keys")
    func decodeUnknownCategory() throws {
        let json = """
        {
          "imageKey": "papier blanc",
          "intention": "Tu commences par ce qui tient.",
          "focus": ["Protège le matin."],
          "reminder": "Une ligne suffit.",
          "categoryInsights": {
            "mood": "Vif. C'est du carburant.",
            "weather": "Le ciel inventé doit être ignoré."
          }
        }
        """

        let response = try AIResponse.decodeGeneratedJSON(
            Data(json.utf8),
            ritualId: UUID(),
            provider: .openai,
            mode: .auto
        )

        #expect(response.categoryInsights?.count == 1)
        #expect(response.categoryInsights?[.mood] == "Vif. C'est du carburant.")
    }
}
