#if DEBUG
import SwiftUI

struct IconFontsCatalog: View {
    private struct Token: Identifiable {
        let id = UUID()
        let name: String
        let font: Font
    }

    private let tokens: [Token] = [
        .init(name: "xs",          font: LumenIconFont.xs),
        .init(name: "sm",          font: LumenIconFont.sm),
        .init(name: "smSemibold",  font: LumenIconFont.smSemibold),
        .init(name: "md",          font: LumenIconFont.md),
        .init(name: "mdMedium",    font: LumenIconFont.mdMedium),
        .init(name: "lg",          font: LumenIconFont.lg),
        .init(name: "lgSemibold",  font: LumenIconFont.lgSemibold),
        .init(name: "xl",          font: LumenIconFont.xl),
        .init(name: "xlSemibold",  font: LumenIconFont.xlSemibold),
        .init(name: "xxl",         font: LumenIconFont.xxl),
        .init(name: "xxxl",        font: LumenIconFont.xxxl),
        .init(name: "monoSm",      font: LumenIconFont.monoSm),
        .init(name: "serifLg",     font: LumenIconFont.serifLg),
        .init(name: "serifXl",     font: LumenIconFont.serifXl),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenSpacing.l) {
                Eyebrow("SF Symbol — sun.max")
                grid(symbol: "sun.max")

                Eyebrow("SF Symbol — alarm")
                grid(symbol: "alarm")

                Eyebrow("Mono — API key")
                ForEach(tokens.filter { $0.name == "monoSm" }) { t in
                    HStack(spacing: LumenSpacing.m) {
                        Text(t.name)
                            .lumenFont(.footnote)
                            .foregroundStyle(LumenColor.textTertiary)
                            .frame(width: 90, alignment: .leading)
                        Text("sk-abc123XYZ")
                            .font(t.font)
                            .foregroundStyle(LumenColor.textPrimary)
                    }
                }

                Eyebrow("Serif glyphs")
                ForEach(tokens.filter { $0.name.hasPrefix("serif") }) { t in
                    HStack(spacing: LumenSpacing.m) {
                        Text(t.name)
                            .lumenFont(.footnote)
                            .foregroundStyle(LumenColor.textTertiary)
                            .frame(width: 90, alignment: .leading)
                        Text("\u{201C}")
                            .font(t.font)
                            .italic()
                            .foregroundStyle(LumenColor.accent)
                    }
                }
            }
            .padding(LumenSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Icon Fonts")
    }

    private func grid(symbol: String) -> some View {
        VStack(spacing: LumenSpacing.s) {
            ForEach(tokens.filter {
                !$0.name.hasPrefix("serif") && $0.name != "monoSm"
            }) { t in
                HStack(spacing: LumenSpacing.m) {
                    Text(t.name)
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textTertiary)
                        .frame(width: 90, alignment: .leading)
                    Image(systemName: symbol)
                        .font(t.font)
                        .foregroundStyle(LumenColor.textPrimary)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    NavigationStack { IconFontsCatalog() }
}
#endif
