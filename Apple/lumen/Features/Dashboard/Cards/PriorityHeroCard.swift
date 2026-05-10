import SwiftUI

/// Post-rituel "Ta priorité" hero — full-width gradient card with status pill,
/// serif italic body, and a decorative concentric-circle arc bottom-right.
/// JSX reference: `Design/designs/screens/screens-shell.jsx:358–392`.
struct PriorityHeroCard: View {
    let text: String
    let insight: String?
    let onTap: () -> Void

    init(text: String, insight: String? = nil, onTap: @escaping () -> Void) {
        self.text = text
        self.insight = insight
        self.onTap = onTap
    }

    private var status: String { "en cours" }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Text("Ta priorité")
                            .font(.system(size: 11, weight: .regular, design: .default))
                            .tracking(0.10 * 11)
                            .textCase(.uppercase)
                            .foregroundStyle(LumenColor.textTertiary)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(LumenColor.accent)
                                .frame(width: 6, height: 6)
                            Text(status)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(LumenColor.textTertiary)
                        }
                    }
                    .padding(.bottom, LumenSpacing.sm3)

                    Text(text)
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .italic()
                        .tracking(-0.015 * 28)
                        .lineSpacing(28 * 0.25)
                        .foregroundStyle(LumenColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let insight, !insight.isEmpty {
                        Text(insight)
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .italic()
                            .lineLimit(2)
                            .foregroundStyle(LumenColor.textSecondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 22)
                .padding(.bottom, 22)

                decorativeArc
                    .frame(width: 120, height: 120)
                    .offset(x: 30, y: 30)
                    .opacity(0.35)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                LinearGradient(
                    colors: [
                        LumenColor.accent.opacity(0.22),
                        LumenColor.accent.opacity(0.06),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(LumenColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard-card-priority")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ta priorité : \(text)")
    }

    private var decorativeArc: some View {
        ZStack {
            Circle()
                .stroke(LumenColor.accent.opacity(0.5), lineWidth: 1)
                .frame(width: 100, height: 100)
            Circle()
                .stroke(LumenColor.accent.opacity(0.35), lineWidth: 1)
                .frame(width: 72, height: 72)
            Circle()
                .fill(LumenColor.accent.opacity(0.4))
                .frame(width: 44, height: 44)
        }
    }
}

#if DEBUG
#Preview {
    PriorityHeroCard(
        text: "Écouter Karim sans préparer ma réponse.",
        onTap: {}
    )
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
