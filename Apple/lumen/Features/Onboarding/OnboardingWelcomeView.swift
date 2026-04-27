import SwiftUI

struct OnboardingWelcomeView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Lumen")
                .font(.system(size: 11, weight: .regular))
                .tracking(11 * 0.22)
                .textCase(.uppercase)
                .foregroundStyle(LumenColor.textSecondary)
                .padding(.top, LumenSpacing.xl)

            Spacer().frame(height: 80)

            KineticText(["Quelques", "minutes", "à", "toi."])
                .font(.system(size: 56, weight: .medium, design: .serif))
                .foregroundStyle(LumenColor.textPrimary)

            Spacer().frame(height: LumenSpacing.l)

            Text("Un rituel matinal pour commencer avec intention.")
                .font(.system(size: 19, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(LumenColor.textPrimary.opacity(0.85))

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
