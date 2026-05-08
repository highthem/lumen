import SwiftUI

enum LumenFont: Sendable, CaseIterable {
    // Sans-serif / system tokens
    case heroDisplay
    case synthesisHero
    case display
    case title1
    case title2
    case title3
    case body
    case bodyBold
    case callout
    case chipLabel
    case footnote
    case caption

    // Serif variants of small body sizes
    case bodySerif        // 17pt
    case bodySerifSm      // 16pt — body.size - 1 pattern
    case bodySerifLg      // 19pt — synthesis body, splash subtitle, AskLumen body
    case calloutSerif     // 15pt
    case footnoteSerif    // 13pt

    // Serif input field sizes
    case inputSerifLg     // 22pt — Q3 SerifUnderlineField

    // Serif display sizes
    case questionnaireQM  // 28pt — Q3 hero
    case displayBold      // 48pt — pitch bold variant
    case wordmark         // 56pt — splash wordmark
    case welcome          // 56pt — onboarding welcome
    case questionnaireHero // 64pt — Q4 hero
    case timePickerHero   // 56pt — alarm-edit + first-alarm wheel (selected row)
    case alarmHero        // 96pt — alarm clock

    var size: CGFloat {
        switch self {
        case .heroDisplay: 64
        case .synthesisHero: 42
        case .display: 48
        case .title1: 32
        case .title2: 24
        case .title3: 20
        case .body, .bodyBold: 17
        case .callout: 15
        case .chipLabel: 14
        case .footnote: 13
        case .caption: 11
        case .bodySerif: 17
        case .bodySerifSm: 16
        case .bodySerifLg: 19
        case .calloutSerif: 15
        case .footnoteSerif: 13
        case .inputSerifLg: 22
        case .questionnaireQM: 28
        case .displayBold: 48
        case .wordmark: 56
        case .welcome: 56
        case .questionnaireHero: 64
        case .timePickerHero: 56
        case .alarmHero: 96
        }
    }

    var weight: Font.Weight {
        switch self {
        case .heroDisplay, .display: .regular
        case .synthesisHero, .title3, .chipLabel: .medium
        case .title1, .title2, .bodyBold: .semibold
        case .body, .callout, .footnote, .caption: .regular
        case .bodySerif, .bodySerifSm, .bodySerifLg, .calloutSerif, .footnoteSerif: .regular
        case .inputSerifLg, .questionnaireQM, .displayBold, .welcome, .questionnaireHero: .medium
        case .wordmark, .alarmHero, .timePickerHero: .regular
        }
    }

    var design: Font.Design {
        switch self {
        case .heroDisplay, .synthesisHero, .display, .title1, .title2: .serif
        case .bodySerif, .bodySerifSm, .bodySerifLg, .calloutSerif, .footnoteSerif: .serif
        case .inputSerifLg, .questionnaireQM, .displayBold, .wordmark, .welcome, .questionnaireHero, .alarmHero, .timePickerHero: .serif
        default: .default
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .heroDisplay: 1.05
        case .synthesisHero: 1.10
        case .display: 1.10
        case .title1: 1.15
        case .title2: 1.20
        case .title3: 1.25
        case .body, .bodyBold: 1.50
        case .callout: 1.45
        case .chipLabel: 1.30
        case .footnote: 1.40
        case .caption: 1.30
        case .bodySerif, .bodySerifSm: 1.50
        case .bodySerifLg: 1 + 2.0 / 19   // 2pt line spacing
        case .calloutSerif: 1.45
        case .footnoteSerif: 1.40
        case .inputSerifLg: 1 + 2.0 / 22  // 2pt
        case .questionnaireQM: 1 + 2.0 / 28 // 2pt
        case .displayBold: 1.10
        case .wordmark: 1.0
        case .welcome: 1.10
        case .questionnaireHero: 1.10
        case .timePickerHero: 1.0
        case .alarmHero: 1.0
        }
    }

    var tracking: CGFloat {
        switch self {
        case .heroDisplay: -0.020 * size
        case .synthesisHero: -0.015 * size
        case .display: -0.015 * size
        case .title1: -0.01 * size
        case .title2, .title3: -0.005 * size
        case .chipLabel: -0.005 * size
        case .footnote: 0.02 * size
        case .caption: 0.22 * size
        case .bodySerifLg: -0.005 * size
        case .inputSerifLg: -0.015 * size
        case .questionnaireQM: -0.015 * size
        case .displayBold: -0.015 * size
        case .wordmark: -0.01 * size
        case .welcome: -0.01 * size
        case .questionnaireHero: -0.0175 * size
        case .timePickerHero: -0.025 * size
        case .alarmHero: -0.03 * size
        default: 0
        }
    }

    var lineSpacing: CGFloat {
        size * (lineHeight - 1.0)
    }

    var font: Font {
        .system(size: size, weight: weight, design: design)
    }
}

extension View {
    func lumenFont(_ token: LumenFont) -> some View {
        self
            .font(token.font)
            .tracking(token.tracking)
            .lineSpacing(token.lineSpacing)
    }
}
