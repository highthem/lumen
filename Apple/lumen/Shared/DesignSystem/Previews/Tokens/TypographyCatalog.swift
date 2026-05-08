#if DEBUG
import SwiftUI

struct TypographyCatalog: View {
    private func name(for token: LumenFont) -> String {
        switch token {
        case .heroDisplay:       return "heroDisplay"
        case .synthesisHero:     return "synthesisHero"
        case .display:           return "display"
        case .title1:            return "title1"
        case .title2:            return "title2"
        case .title3:            return "title3"
        case .body:              return "body"
        case .bodyBold:          return "bodyBold"
        case .callout:           return "callout"
        case .chipLabel:         return "chipLabel"
        case .footnote:          return "footnote"
        case .caption:           return "caption"
        case .bodySerif:         return "bodySerif"
        case .bodySerifSm:       return "bodySerifSm"
        case .bodySerifLg:       return "bodySerifLg"
        case .calloutSerif:      return "calloutSerif"
        case .footnoteSerif:     return "footnoteSerif"
        case .inputSerifLg:      return "inputSerifLg"
        case .questionnaireQM:   return "questionnaireQM"
        case .displayBold:       return "displayBold"
        case .wordmark:          return "wordmark"
        case .welcome:           return "welcome"
        case .questionnaireHero: return "questionnaireHero"
        case .timePickerHero:    return "timePickerHero"
        case .alarmHero:         return "alarmHero"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenSpacing.l) {
                ForEach(LumenFont.allCases, id: \.self) { token in
                    VStack(alignment: .leading, spacing: LumenSpacing.xs) {
                        HStack(spacing: LumenSpacing.s) {
                            Text(name(for: token))
                                .lumenFont(.caption)
                                .foregroundStyle(LumenColor.textTertiary)
                            Text("\(Int(token.size))pt · \(token.design == .serif ? "serif" : "sans")")
                                .lumenFont(.caption)
                                .foregroundStyle(LumenColor.textTertiary)
                        }
                        Text("Le matin se lève doucement.")
                            .lumenFont(token)
                            .foregroundStyle(LumenColor.textPrimary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(LumenSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Typography")
    }
}

#Preview("Light") {
    NavigationStack { TypographyCatalog() }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack { TypographyCatalog() }
        .preferredColorScheme(.dark)
}
#endif
