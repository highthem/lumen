import SwiftUI

/// Idle-state hero per `Design/designs/screens/screens-shell.jsx:208–263`:
/// a 28pt-radius card with a radial gradient at top center, the rising-sun
/// `BreathingOrb` (hero size), the "Ton matin t'attend." invitation, the
/// 4q/5min subtitle, and the gold full-width CTA.
struct IdleHeroCard: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            BreathingOrb(size: .hero)
                .padding(.bottom, 18)

            VStack(spacing: 6) {
                Text("Ton matin t'attend.")
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .italic()
                    .tracking(-0.015 * 24)
                    .foregroundStyle(LumenColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("4 questions · 5 minutes · une intention pour la journée")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundStyle(LumenColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, LumenSpacing.l)

            PrimaryCTA("Commencer le rituel", action: onStart)
                .accessibilityIdentifier("ritual-cta")
                .padding(.top, 22)
        }
        .padding(.top, 32)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(
            RadialGradient(
                colors: [
                    LumenColor.accent.opacity(0.18),
                    LumenColor.accent.opacity(0.04),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 320
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(LumenColor.divider, lineWidth: 1)
        )
        .accessibilityIdentifier("dashboard-idle-hero")
    }
}

#if DEBUG
#Preview {
    IdleHeroCard(onStart: {})
        .padding(LumenSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LumenColor.bgPrimary)
}
#endif
