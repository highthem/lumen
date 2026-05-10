import SwiftUI

/// Bento Présence card — eyebrow + (icon + 14pt value text). 110-min-height,
/// 16pt padding, 20pt radius. JSX reference: `screens-shell.jsx:485–498`.
struct PresenceCard: View {
    let state: PresenceState
    let insight: String?
    let onTap: () -> Void

    init(state: PresenceState, insight: String? = nil, onTap: @escaping () -> Void = {}) {
        self.state = state
        self.insight = insight
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Présence")
                Spacer(minLength: 0)
                HStack(alignment: .center, spacing: LumenSpacing.s) {
                    icon
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .tracking(-0.005 * 14)
                        .foregroundStyle(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .italic(state == .skipped || state == .notStarted)
                }
                if let insight, !insight.isEmpty {
                    Text(insight)
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .italic()
                        .lineLimit(2)
                        .foregroundStyle(LumenColor.textSecondary)
                        .padding(.top, 4)
                }
            }
            .padding(LumenSpacing.m)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LumenColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard-card-presence")
    }

    private var label: String {
        switch state {
        case .completed:  return "60 sec"
        case .partial:    return "Quelques sec"
        case .skipped:    return "Pas ce matin"
        case .notStarted: return "Pas encore"
        }
    }

    private var textColor: Color {
        switch state {
        case .completed, .partial: return LumenColor.textPrimary
        case .skipped, .notStarted: return LumenColor.textSecondary
        }
    }

    @ViewBuilder
    private var icon: some View {
        let diameter: CGFloat = 18
        switch state {
        case .completed:
            Circle()
                .fill(LumenColor.accent)
                .frame(width: diameter, height: diameter)
        case .partial:
            ZStack {
                Circle().stroke(LumenColor.accent.opacity(0.6), lineWidth: 1.5)
                Circle()
                    .trim(from: 0, to: 0.5)
                    .fill(LumenColor.accent.opacity(0.6))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: diameter, height: diameter)
        case .skipped, .notStarted:
            Circle()
                .stroke(LumenColor.divider, lineWidth: 1.5)
                .frame(width: diameter, height: diameter)
        }
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 10) {
        PresenceCard(state: .completed)
        PresenceCard(state: .partial)
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
