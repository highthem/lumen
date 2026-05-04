import SwiftUI

struct OnboardingPitchView: View {
    @Bindable var vm: OnboardingViewModel
    @State private var showSecondLine = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { vm.goBack() }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(LumenColor.textPrimary)
                        .font(LumenIconFont.xxl)
                }
                Spacer()
                ProgressDots4(current: 1)
                Spacer()
            }
            .padding(.top, LumenSpacing.xl)

            Spacer().frame(height: LumenSpacing.huge)

            KineticText(["Cinq", "minutes."])
                .lumenFont(.displayBold)
                .foregroundStyle(LumenColor.textPrimary)

            Spacer().frame(height: LumenSpacing.s)

            if showSecondLine {
                KineticText(["Pas", "plus."])
                    .lumenFont(.display)
                    .italic()
                    .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.ring))
            } else {
                Color.clear.frame(height: LumenSpacing.huge - LumenSpacing.xs2)
            }

            Spacer().frame(height: LumenSpacing.xl)

            Text("Pour cadrer ta journée avant qu'elle ne te cadre.")
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)

            Spacer()

            PrimaryCTA("Suivant") { vm.advance() }
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.bottom, LumenSpacing.xl)
        .task {
            try? await Task.sleep(for: LumenDelay.scene)
            showSecondLine = true
        }
    }
}
