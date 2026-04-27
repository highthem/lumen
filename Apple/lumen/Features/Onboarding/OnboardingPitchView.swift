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
                        .font(.system(size: 17, weight: .medium))
                }
                Spacer()
                ProgressDots4(current: 1)
                Spacer()
            }
            .padding(.top, LumenSpacing.xl)

            Spacer().frame(height: LumenSpacing.huge)

            KineticText(["Cinq", "minutes."])
                .font(.system(size: 48, weight: .medium, design: .serif))
                .foregroundStyle(LumenColor.textPrimary)

            Spacer().frame(height: LumenSpacing.s)

            if showSecondLine {
                KineticText(["Pas", "plus."])
                    .font(.system(size: 48, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(LumenColor.textPrimary.opacity(0.55))
            } else {
                Color.clear.frame(height: 58)
            }

            Spacer().frame(height: LumenSpacing.xl)

            Text("Pour cadrer ta journée avant qu'elle ne te cadre.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(LumenColor.textSecondary)

            Spacer()

            PrimaryCTA("Suivant") { vm.advance() }
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.bottom, LumenSpacing.xl)
        .task {
            try? await Task.sleep(for: .milliseconds(600))
            showSecondLine = true
        }
    }
}
