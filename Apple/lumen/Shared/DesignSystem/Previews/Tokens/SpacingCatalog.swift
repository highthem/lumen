#if DEBUG
import SwiftUI

struct SpacingCatalog: View {
    private struct Token: Identifiable {
        let id = UUID()
        let name: String
        let value: CGFloat
    }

    private let tokens: [Token] = [
        .init(name: "xxs",     value: LumenSpacing.xxs),
        .init(name: "xs",      value: LumenSpacing.xs),
        .init(name: "xs2",     value: LumenSpacing.xs2),
        .init(name: "s",       value: LumenSpacing.s),
        .init(name: "sm",      value: LumenSpacing.sm),
        .init(name: "sm2",     value: LumenSpacing.sm2),
        .init(name: "sm3",     value: LumenSpacing.sm3),
        .init(name: "m",       value: LumenSpacing.m),
        .init(name: "ml",      value: LumenSpacing.ml),
        .init(name: "ml2",     value: LumenSpacing.ml2),
        .init(name: "lp",      value: LumenSpacing.lp),
        .init(name: "l",       value: LumenSpacing.l),
        .init(name: "l2",      value: LumenSpacing.l2),
        .init(name: "xl0",     value: LumenSpacing.xl0),
        .init(name: "xl",      value: LumenSpacing.xl),
        .init(name: "xl2",     value: LumenSpacing.xl2),
        .init(name: "xl3",     value: LumenSpacing.xl3),
        .init(name: "xl4",     value: LumenSpacing.xl4),
        .init(name: "xxl",     value: LumenSpacing.xxl),
        .init(name: "xxl2",    value: LumenSpacing.xxl2),
        .init(name: "huge",    value: LumenSpacing.huge),
        .init(name: "xxh",     value: LumenSpacing.xxh),
        .init(name: "hero",    value: LumenSpacing.hero),
        .init(name: "heroLg",  value: LumenSpacing.heroLg),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                ForEach(tokens) { t in
                    HStack(spacing: LumenSpacing.m) {
                        Text(t.name)
                            .lumenFont(.footnote)
                            .foregroundStyle(LumenColor.textPrimary)
                            .frame(width: 60, alignment: .leading)
                        Text("\(Int(t.value))")
                            .lumenFont(.caption)
                            .foregroundStyle(LumenColor.textTertiary)
                            .frame(width: 30, alignment: .trailing)
                        Rectangle()
                            .fill(LumenColor.accent)
                            .frame(width: t.value, height: 12)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        Spacer()
                    }
                }
            }
            .padding(LumenSpacing.l)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Spacing")
    }
}

#Preview {
    NavigationStack { SpacingCatalog() }
}
#endif
