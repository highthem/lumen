import SwiftUI

struct OnboardingWelcomeView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Lumen")
                .lumenFont(.caption)
                .textCase(.uppercase)
                .foregroundStyle(LumenColor.textSecondary)
                .padding(.top, LumenSpacing.xl)

            Spacer().frame(height: LumenSpacing.xxh)

            KineticText(["Quelques", "minutes", "à", "toi."])
                .lumenFont(.welcome)
                .foregroundStyle(LumenColor.textPrimary)

            Spacer().frame(height: LumenSpacing.l)

            Text("Un rituel matinal pour commencer avec intention.")
                .lumenFont(.bodySerifLg)
                .italic()
                .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.pressed))

            Spacer()

            VStack(spacing: LumenSpacing.s) {
                PrimaryCTA("Commencer") { vm.advance() }
                GhostCTA(title: "J'ai déjà un compte") { vm.advance() }
            }
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.bottom, LumenSpacing.xl)
    }
}
