#if DEBUG
import SwiftUI

enum PreviewSamples {
    static let symbols: [String] = [
        "sun.max",
        "alarm",
        "mic",
        "speaker.wave.2",
        "bubble.left",
        "moon.stars",
        "sparkles",
        "checkmark.circle"
    ]

    static let shortLine = "Bonjour, prête à respirer."
    static let mediumLine = "Trois choses à honorer ce matin avant de plonger dans le bruit."
    static let longParagraph =
        "Ta journée commence à respirer doucement. Garde une intention claire, pose une seule pierre, et observe le reste s'organiser autour."

    static let intentionWords: [String] = ["Honore", "ta", "lenteur", "et", "écoute", "ce", "qui", "monte"]

    static let alarmDate: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 7; c.hour = 6; c.minute = 45
        return Calendar.current.date(from: c) ?? .now
    }()

    static func wrapped<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(LumenSpacing.l)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LumenColor.bgPrimary)
    }
}
#endif
