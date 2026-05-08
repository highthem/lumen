import SwiftUI

/// Q2 — Énergie. Breathing orb that scales with the chosen level (80→200pt)
/// over a horizontal slider. Replaces the V8-V10 chip stack: design comment
/// in `screens-flow.jsx:84-256` is explicit — Q2's differentiator from Q1
/// is *form* (contained orb + horizontal gesture), not chromatic background.
struct Q2EnergyView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    private static let labels = ["à plat", "faiblard", "moyen", "bien chargé", "au top"]
    private static let subs = [
        "le corps demande lenteur",
        "tout est un peu loin",
        "présent, pas encore lancé",
        "le moteur est prêt",
        "on peut bouger des montagnes"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            ProgressDots4(current: 1)

            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                Eyebrow("02 / 04 · Énergie")
                Text("Quelle énergie\nce matin ?")
                    .lumenFont(.title1)
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: LumenSpacing.xl) {
                Spacer(minLength: 0)
                EnergyOrb(level: vm.energyLevel)
                    .accessibilityIdentifier("energy-orb")
                wordSubtitle
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            EnergySlider(level: $vm.energyLevel)
                .accessibilityIdentifier("energy-slider")

            FooterRow(
                backTitle: "Retour",
                nextTitle: "Suivant",
                isNextEnabled: true,
                onBack: onBack,
                onNext: onNext
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, LumenSpacing.xl0)
        .padding(.bottom, LumenSpacing.l)
    }

    private var wordSubtitle: some View {
        VStack(spacing: 4) {
            Text(Self.labels[vm.energyLevel])
                .lumenFont(.title2)
                .italic()
                .foregroundStyle(LumenColor.textPrimary)
                .id("energy-label-\(vm.energyLevel)")
                .transition(.opacity)
            Text(Self.subs[vm.energyLevel])
                .lumenFont(.footnoteSerif)
                .italic()
                .foregroundStyle(LumenColor.textSecondary)
        }
        .multilineTextAlignment(.center)
        .animation(.easeOut(duration: 0.35), value: vm.energyLevel)
    }
}

#if DEBUG
#Preview {
    Q2EnergyView(vm: .preview, onNext: {}, onBack: {})
        .preferredColorScheme(.dark)
}
#endif
