import SwiftUI

/// Full-width post-rituel Gratitude card: eyebrow + opening-quote glyph
/// (serif 38pt italic accent) + serif italic 17pt body in textPrimary @ 0.75.
/// JSX reference: `Design/designs/screens/screens-shell.jsx:458–480`.
struct GratitudeQuoteCard: View {
    let text: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Gratitude")
                    .padding(.bottom, LumenSpacing.s)
                HStack(spacing: LumenSpacing.sm) {
                    Text("\u{201C}")
                        .font(.system(size: 38, weight: .regular, design: .serif))
                        .italic()
                        .lineSpacing(-15)
                        .foregroundStyle(LumenColor.accent)
                        .padding(.top, 6)
                        .accessibilityHidden(true)
                    Text(text)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .italic()
                        .tracking(-0.005 * 17)
                        .lineSpacing(17 * 0.40)
                        .foregroundStyle(LumenColor.textPrimary.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\u{201D}")
                        .font(.system(size: 38, weight: .regular, design: .serif))
                        .italic()
                        .lineSpacing(-15)
                        .foregroundStyle(LumenColor.accent)
                        .padding(.top, 6)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LumenColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard-card-gratitude")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Gratitude : \(text)")
    }
}

#if DEBUG
#Preview("multiple lines") {
    GratitudeQuoteCard(
        text: "Le silence avant que les enfants se lèvent.",
        onTap: {}
    )
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#Preview("single lines") {
    GratitudeQuoteCard(
        text: "Le silence.",
        onTap: {}
    )
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
