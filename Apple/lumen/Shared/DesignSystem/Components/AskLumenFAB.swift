import SwiftUI

/// Labeled "Ask Lumen" floating action button (V8 — replaces the round "?").
struct AskLumenFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LumenSpacing.s) {
                Image(systemName: "bubble.left")
                    .font(LumenIconFont.lgSemibold)
                Text("Ask Lumen")
                    .lumenFont(.callout)
            }
            .foregroundStyle(LumenColor.bgPrimary)
            .padding(.horizontal, LumenSpacing.l)
            .frame(height: LumenSize.fab)
            .background(
                Capsule(style: .continuous)
                    .fill(LumenColor.accent)
            )
            .lumenShadow(.elevated)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ask-lumen-fab")
        .accessibilityLabel("Ask Lumen")
        .accessibilityHint("Pose une question à Lumen sur ton matin")
    }
}

#if DEBUG
#Preview {
    AskLumenFAB {}
        .padding(LumenSpacing.l)
        .background(LumenColor.bgPrimary)
}
#endif
