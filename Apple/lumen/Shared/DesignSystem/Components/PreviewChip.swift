import SwiftUI

/// Italic serif pill shown in the Idle "Ce matin tu vas explorer" row.
/// JSX reference: `screens-shell.jsx:303–318` — `01 · Humeur` etc.
struct PreviewChip: View {
    let index: Int       // 1-based; rendered as `01`, `02`, …
    let label: String

    var body: some View {
        Text("\(formattedIndex) · \(label)")
            .font(.system(size: 13, weight: .regular, design: .serif))
            .italic()
            .foregroundStyle(LumenColor.textPrimary)
            .padding(.horizontal, LumenSpacing.sm3)
            .padding(.vertical, LumenSpacing.s)
            .background(LumenColor.bgSecondary)
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(LumenColor.divider, lineWidth: 1)
            )
            .accessibilityLabel("Catégorie \(index) \(label)")
    }

    private var formattedIndex: String {
        index < 10 ? "0\(index)" : "\(index)"
    }
}

#if DEBUG
#Preview {
    HStack(spacing: LumenSpacing.s) {
        PreviewChip(index: 1, label: "Humeur")
        PreviewChip(index: 2, label: "Énergie")
        PreviewChip(index: 3, label: "Priorité")
        PreviewChip(index: 4, label: "Gratitude")
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
