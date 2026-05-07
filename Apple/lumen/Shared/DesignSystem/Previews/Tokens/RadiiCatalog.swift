#if DEBUG
import SwiftUI

struct RadiiCatalog: View {
    private struct Token: Identifiable {
        let id = UUID()
        let name: String
        let value: CGFloat
    }

    private let tokens: [Token] = [
        .init(name: "s",     value: LumenRadius.s),
        .init(name: "m",     value: LumenRadius.m),
        .init(name: "l",     value: LumenRadius.l),
        .init(name: "xl",    value: LumenRadius.xl),
        .init(name: "round", value: LumenRadius.round),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: LumenSpacing.l) {
                ForEach(tokens) { t in
                    HStack(spacing: LumenSpacing.m) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.name)
                                .lumenFont(.callout)
                                .foregroundStyle(LumenColor.textPrimary)
                            Text("\(Int(t.value))pt")
                                .lumenFont(.caption)
                                .foregroundStyle(LumenColor.textTertiary)
                        }
                        .frame(width: 80, alignment: .leading)

                        RoundedRectangle(cornerRadius: t.value, style: .continuous)
                            .fill(LumenColor.accentMuted)
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: t.value, style: .continuous)
                                    .strokeBorder(LumenColor.accent, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(LumenSpacing.l)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Radii")
    }
}

#Preview {
    NavigationStack { RadiiCatalog() }
}
#endif
