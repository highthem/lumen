import SwiftUI

/// Labeled "Ask Lumen" floating action button (V8 — replaces the round "?").
struct AskLumenFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Ask Lumen")
                    .font(.system(size: 15, weight: .medium))
                    .tracking(-0.075)
            }
            .foregroundStyle(LumenColor.bgPrimary)
            .padding(.horizontal, 18)
            .frame(height: 48)
            .background(
                Capsule(style: .continuous)
                    .fill(LumenColor.accent)
            )
            .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask Lumen")
        .accessibilityHint("Pose une question à Lumen sur ton matin")
    }
}
