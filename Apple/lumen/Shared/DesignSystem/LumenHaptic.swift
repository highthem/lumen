import UIKit

/// Haptic policy per design system spec (`02-design-system.html` §03 Motion / Haptics).
/// Allowed: alarm silence (`.medium`), timer end + mood select (`.soft`), synthesis ready (`.success`).
/// Forbidden everywhere else — transitions, scroll, hover, mid-questionnaire — to keep the calm.
enum LumenHaptic {
    /// One strong tap per day — only for the "Silence" alarm action.
    static func alarmSilence() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// End of the presence timer.
    static func timerEnd() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Q1 mood selector — discrete-level snap.
    static func moodSelect() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Synthesis fully revealed and ready to read.
    static func synthesisReady() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
