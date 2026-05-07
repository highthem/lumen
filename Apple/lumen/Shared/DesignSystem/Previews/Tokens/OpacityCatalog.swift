#if DEBUG
import SwiftUI

struct OpacityCatalog: View {
    private struct Token: Identifiable {
        let id = UUID()
        let name: String
        let value: Double
    }

    private let semantic: [Token] = [
        .init(name: "surfaceFill", value: LumenOpacity.surfaceFill),
        .init(name: "glow",        value: LumenOpacity.glow),
        .init(name: "subtle",      value: LumenOpacity.subtle),
        .init(name: "disabled",    value: LumenOpacity.disabled),
        .init(name: "muted",       value: LumenOpacity.muted),
        .init(name: "dim",         value: LumenOpacity.dim),
        .init(name: "ring",        value: LumenOpacity.ring),
        .init(name: "waveform",    value: LumenOpacity.waveform),
        .init(name: "arc",         value: LumenOpacity.arc),
        .init(name: "pressed",     value: LumenOpacity.pressed),
    ]

    private let percent: [Token] = [
        .init(name: "p04", value: LumenOpacity.p04),
        .init(name: "p06", value: LumenOpacity.p06),
        .init(name: "p08", value: LumenOpacity.p08),
        .init(name: "p10", value: LumenOpacity.p10),
        .init(name: "p16", value: LumenOpacity.p16),
        .init(name: "p22", value: LumenOpacity.p22),
        .init(name: "p25", value: LumenOpacity.p25),
        .init(name: "p28", value: LumenOpacity.p28),
        .init(name: "p32", value: LumenOpacity.p32),
        .init(name: "p35", value: LumenOpacity.p35),
        .init(name: "p38", value: LumenOpacity.p38),
        .init(name: "p40", value: LumenOpacity.p40),
        .init(name: "p42", value: LumenOpacity.p42),
        .init(name: "p60", value: LumenOpacity.p60),
        .init(name: "p65", value: LumenOpacity.p65),
        .init(name: "p70", value: LumenOpacity.p70),
        .init(name: "p78", value: LumenOpacity.p78),
        .init(name: "p88", value: LumenOpacity.p88),
        .init(name: "p94", value: LumenOpacity.p94),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenSpacing.l) {
                section("Semantic", tokens: semantic)
                section("Percentage", tokens: percent)
            }
            .padding(LumenSpacing.l)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Opacity")
    }

    private func section(_ title: String, tokens: [Token]) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow(title)
            ForEach(tokens) { t in
                HStack(spacing: LumenSpacing.m) {
                    Text(t.name)
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textPrimary)
                        .frame(width: 90, alignment: .leading)
                    Text(String(format: "%.2f", t.value))
                        .lumenFont(.caption)
                        .foregroundStyle(LumenColor.textTertiary)
                        .frame(width: 40, alignment: .trailing)
                    RoundedRectangle(cornerRadius: LumenRadius.s)
                        .fill(LumenColor.accent.opacity(t.value))
                        .frame(height: 22)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { OpacityCatalog() }
}
#endif
