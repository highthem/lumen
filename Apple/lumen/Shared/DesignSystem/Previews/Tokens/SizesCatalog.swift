#if DEBUG
import SwiftUI

struct SizesCatalog: View {
    private struct Token: Identifiable {
        let id = UUID()
        let name: String
        let value: CGFloat
        let group: String
    }

    private let tokens: [Token] = [
        .init(name: "dotSm",        value: LumenSize.dotSm,        group: "Indicator dots"),
        .init(name: "dotMd",        value: LumenSize.dotMd,        group: "Indicator dots"),
        .init(name: "dotLg",        value: LumenSize.dotLg,        group: "Indicator dots"),

        .init(name: "iconXs",       value: LumenSize.iconXs,       group: "Icons"),
        .init(name: "iconSm",       value: LumenSize.iconSm,       group: "Icons"),
        .init(name: "iconMd",       value: LumenSize.iconMd,       group: "Icons"),
        .init(name: "iconLg",       value: LumenSize.iconLg,       group: "Icons"),
        .init(name: "iconXl",       value: LumenSize.iconXl,       group: "Icons"),

        .init(name: "buttonSm",     value: LumenSize.buttonSm,     group: "Controls"),
        .init(name: "fab",          value: LumenSize.fab,          group: "Controls"),
        .init(name: "cta",          value: LumenSize.cta,          group: "Controls"),
        .init(name: "listenPlayer", value: LumenSize.listenPlayer, group: "Controls"),

        .init(name: "iconBtn",      value: LumenSize.iconBtn,      group: "Controls"),
        .init(name: "mic",          value: LumenSize.mic,          group: "Mic / Breath"),
        .init(name: "micLg",        value: LumenSize.micLg,        group: "Mic / Breath"),
        .init(name: "breathCircle", value: LumenSize.breathCircle, group: "Mic / Breath"),

        .init(name: "ruleSm",       value: LumenSize.ruleSm,       group: "Rules / Inputs"),
        .init(name: "formInput",    value: LumenSize.formInput,    group: "Rules / Inputs"),
        .init(name: "editorMin",    value: LumenSize.editorMin,    group: "Rules / Inputs"),
        .init(name: "halfMod",      value: LumenSize.halfMod,      group: "Rules / Inputs"),

        .init(name: "blockMin",     value: LumenSize.blockMin,     group: "Vertical blocks"),
        .init(name: "blockSm",      value: LumenSize.blockSm,      group: "Vertical blocks"),
        .init(name: "blockMd",      value: LumenSize.blockMd,      group: "Vertical blocks"),
        .init(name: "blockLg",      value: LumenSize.blockLg,      group: "Vertical blocks"),
        .init(name: "blockReveal",  value: LumenSize.blockReveal,  group: "Vertical blocks"),
    ]

    private var grouped: [(group: String, items: [Token])] {
        let order = ["Indicator dots", "Icons", "Controls", "Mic / Breath", "Rules / Inputs", "Vertical blocks"]
        return order.map { g in (g, tokens.filter { $0.group == g }) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenSpacing.l) {
                ForEach(grouped, id: \.group) { section in
                    VStack(alignment: .leading, spacing: LumenSpacing.s) {
                        Eyebrow(section.group)
                        ForEach(section.items) { t in
                            HStack(spacing: LumenSpacing.m) {
                                Text(t.name)
                                    .lumenFont(.footnote)
                                    .foregroundStyle(LumenColor.textPrimary)
                                    .frame(width: 110, alignment: .leading)
                                Text("\(Int(t.value))pt")
                                    .lumenFont(.caption)
                                    .foregroundStyle(LumenColor.textTertiary)
                                    .frame(width: 40, alignment: .trailing)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(LumenColor.accentMuted)
                                    .frame(width: min(t.value, 240), height: min(t.value, 24))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(LumenSpacing.l)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Sizes")
    }
}

#Preview {
    NavigationStack { SizesCatalog() }
}
#endif
