#if DEBUG
import SwiftUI

enum ComponentEntry: String, CaseIterable, Identifiable {
    case primaryCTA, secondaryCTA, ghostCTA, micCTA, askLumenFAB
    case lumenToggle, segmentedControl
    case serifUnderlineField, chromaticSlider, wheelTimePicker
    case dashboardCard, cardDeck, footerRow, waterfallStatusList
    case priorityIcon
    case eyebrow, sectionTitle, progressDots4, appleIntelligenceBadge
    case alarmSunrise, breathingCircle, slowPulse
    case kineticText, liveTranscript
    case toast, halfSheet, listenPlayer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .primaryCTA:             return "PrimaryCTA"
        case .secondaryCTA:           return "SecondaryCTA"
        case .ghostCTA:               return "GhostCTA"
        case .micCTA:                 return "MicCTA"
        case .askLumenFAB:            return "AskLumenFAB"
        case .lumenToggle:            return "LumenToggle"
        case .segmentedControl:       return "LumenSegmentedControl"
        case .serifUnderlineField:    return "SerifUnderlineField"
        case .chromaticSlider:        return "ChromaticSlider"
        case .wheelTimePicker:        return "WheelTimePicker"
        case .dashboardCard:          return "DashboardCard"
        case .cardDeck:               return "CardDeck"
        case .footerRow:              return "FooterRow"
        case .waterfallStatusList:    return "WaterfallStatusList"
        case .priorityIcon:           return "PriorityIcon"
        case .eyebrow:                return "Eyebrow"
        case .sectionTitle:           return "SectionTitle"
        case .progressDots4:          return "ProgressDots4"
        case .appleIntelligenceBadge: return "AppleIntelligenceBadge"
        case .alarmSunrise:           return "AlarmSunrise"
        case .breathingCircle:        return "BreathingCircle"
        case .slowPulse:              return "SlowPulse"
        case .kineticText:            return "KineticText"
        case .liveTranscript:         return "LiveTranscript"
        case .toast:                  return "Toast"
        case .halfSheet:              return "HalfSheet"
        case .listenPlayer:           return "ListenPlayer"
        }
    }

    var group: String {
        switch self {
        case .primaryCTA, .secondaryCTA, .ghostCTA, .micCTA, .askLumenFAB:
            return "Buttons & CTAs"
        case .lumenToggle, .segmentedControl:
            return "Controls"
        case .serifUnderlineField, .chromaticSlider, .wheelTimePicker:
            return "Inputs"
        case .dashboardCard, .cardDeck, .footerRow, .waterfallStatusList:
            return "Cards & Rows"
        case .priorityIcon, .eyebrow, .sectionTitle, .progressDots4, .appleIntelligenceBadge:
            return "Atoms & Glyphs"
        case .alarmSunrise, .breathingCircle, .slowPulse, .kineticText, .liveTranscript:
            return "Animations"
        case .toast, .halfSheet, .listenPlayer:
            return "Feedback & Media"
        }
    }
}

struct ComponentsIndex: View {
    private var grouped: [(group: String, items: [ComponentEntry])] {
        let order = [
            "Buttons & CTAs", "Controls", "Inputs", "Cards & Rows",
            "Atoms & Glyphs", "Animations", "Feedback & Media"
        ]
        return order.map { g in (g, ComponentEntry.allCases.filter { $0.group == g }) }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.group) { section in
                Section(section.group) {
                    ForEach(section.items) { entry in
                        NavigationLink(entry.displayName) {
                            ComponentDetailView(entry: entry)
                        }
                    }
                }
            }
        }
        .navigationTitle("Components")
    }
}

#Preview {
    NavigationStack { ComponentsIndex() }
}
#endif
