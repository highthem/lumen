import SwiftUI

/// Bento Humeur card: eyebrow + (color swatch + serif italic value + level
/// caption). JSX reference: `screens-shell.jsx:396–420`.
struct MoodCard: View {
    let mood: MoodSummary?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Humeur")
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: LumenSpacing.sm) {
                    MoodSwatchOrb(level: mood?.level ?? 2)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(displayValue)
                            .font(.system(size: 19, weight: .medium, design: .serif))
                            .italic()
                            .tracking(-0.005 * 19)
                            .foregroundStyle(LumenColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let level = mood?.level {
                            // Q1 slider may emit either 0…4 (current spec) or 0…9 (legacy
                            // fixture). Normalize to a 1…5 caption either way.
                            let normalized = level <= 4 ? level + 1 : Int(round(Double(level) / 9.0 * 4.0)) + 1
                            Text("niveau \(min(5, max(1, normalized)))/5")
                                .font(.system(size: 11))
                                .foregroundStyle(LumenColor.textTertiary)
                        }
                    }
                }
            }
            .padding(LumenSpacing.m)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LumenColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard-card-mood")
    }

    private var displayValue: String {
        if let tag = mood?.tag, !tag.isEmpty { return tag.lowercased() }
        return "non renseigné"
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 10) {
        MoodCard(mood: MoodSummary(level: 2, tag: "posé"), onTap: {})
        MoodCard(mood: nil, onTap: {})
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
