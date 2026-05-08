import SwiftUI

/// Idle-state hero per `~/Downloads/lumen/project/03-mockups.html` § "Dashboard
/// · 3 états" → "Idle". A single rounded card holding the sun glyph, the
/// "Ton matin t'attend." invitation, the 4q/5min subtitle, and the gold CTA.
///
/// The sun glyph reuses the canonical sun palette (`LumenColor.Sunrise.*`)
/// defined for the alarm ringing screen — same morning visual language
/// across both surfaces. The disc fades fully to `.clear` at the rim so the
/// edge blends into the card background rather than leaving a brown halo.
struct IdleHeroCard: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            sunGlyph
                .padding(.top, LumenSpacing.m)
                .padding(.bottom, LumenSpacing.s)

            VStack(spacing: LumenSpacing.s) {
                Text("Ton matin t'attend.")
                    .lumenFont(.title2)
                    .foregroundStyle(LumenColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("4 questions · 5 minutes · une intention pour la journée")
                    .lumenFont(.footnote)
                    .foregroundStyle(LumenColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, LumenSpacing.m)

            PrimaryCTA("Commencer le rituel", action: onStart)
                .accessibilityIdentifier("ritual-cta")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, LumenSpacing.l)
        .padding(.bottom, LumenSpacing.l)
        .background(LumenColor.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.xl, style: .continuous))
        .accessibilityIdentifier("dashboard-idle-hero")
    }

    /// Rising-sun glyph: a half-cut disc whose halo bleeds upward into the
    /// card's title area. The disc is positioned so its bottom is clipped
    /// at the band edge (= horizon line). The halo is offset up so its
    /// bright center aligns with the disc center, and its outer glow
    /// radiates above the disc into the empty space at the top of the card.
    private var sunGlyph: some View {
        ZStack(alignment: .top) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            LumenColor.Sunrise.sun.opacity(0.42),
                            LumenColor.Sunrise.sun.opacity(0.14),
                            LumenColor.Sunrise.sun.opacity(0.04),
                            .clear
                        ],
                        center: .center,
                        startRadius: 24,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 14)
                .offset(y: -55)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            LumenColor.Sunrise.halo,
                            LumenColor.Sunrise.sun,
                            LumenColor.Sunrise.sun.opacity(0.45),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 75
                    )
                )
                .frame(width: 140, height: 140)
                .offset(y: 15)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .clipped()
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    VStack {
        IdleHeroCard(onStart: {})
            .padding(LumenSpacing.l)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LumenColor.bgPrimary)
}
#endif
