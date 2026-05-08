import SwiftUI

struct PresenceCard: View {
    let state: PresenceState
    let onTap: () -> Void

    init(state: PresenceState, onTap: @escaping () -> Void = {}) {
        self.state = state
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                Eyebrow("Présence")

                HStack(alignment: .center, spacing: LumenSpacing.s) {
                    circleIcon
                    Text(label)
                        .lumenFont(state == .skipped || state == .notStarted ? .calloutSerif : .body)
                        .italic(state == .skipped || state == .notStarted)
                        .foregroundStyle(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(LumenSpacing.l)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var label: String {
        switch state {
        case .completed:  return "60 secondes prises"
        case .partial:    return "Quelques secondes"
        case .skipped:    return "Pas de présence ce matin"
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
    private var circleIcon: some View {
        let diameter: CGFloat = 22
        switch state {
        case .completed:
            Circle()
                .fill(LumenColor.accent)
                .frame(width: diameter, height: diameter)
        case .partial:
            ZStack {
                Circle()
                    .stroke(LumenColor.accent.opacity(LumenOpacity.p60), lineWidth: 1.5)
                Circle()
                    .trim(from: 0, to: 0.5)
                    .fill(LumenColor.accent.opacity(LumenOpacity.p60))
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
    VStack(spacing: LumenSpacing.m) {
        PresenceCard(state: .completed)
        PresenceCard(state: .partial)
        PresenceCard(state: .skipped)
        PresenceCard(state: .notStarted)
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
