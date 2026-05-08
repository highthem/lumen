import SwiftUI

struct Q2EnergyView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

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

            Spacer(minLength: LumenSpacing.s)

            chipsStack
                .frame(maxWidth: .infinity)

            Spacer(minLength: LumenSpacing.s)

            FooterRow(
                backTitle: "Retour",
                nextTitle: "Suivant",
                isNextEnabled: vm.energyLevel != nil,
                onBack: onBack,
                onNext: onNext
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, LumenSpacing.xl0)
        .padding(.bottom, LumenSpacing.l)
    }

    @ViewBuilder
    private var chipsStack: some View {
        VStack(spacing: LumenSpacing.sm2) {
            ForEach(Array(EnergyLevel.allCases.enumerated()), id: \.element) { index, level in
                chip(for: level, identifier: index + 1)
            }
        }
    }

    private func chip(for level: EnergyLevel, identifier: Int) -> some View {
        let isSelected = vm.energyLevel == level
        return Button {
            vm.energyLevel = (vm.energyLevel == level) ? nil : level
        } label: {
            HStack(alignment: .center, spacing: LumenSpacing.m) {
                VStack(alignment: .leading, spacing: LumenSpacing.xxs) {
                    Text(level.displayName)
                        .lumenFont(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? LumenColor.accent : LumenColor.textPrimary)
                    Text(level.subtitle)
                        .lumenFont(.footnoteSerif)
                        .italic()
                        .foregroundStyle(LumenColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Circle()
                        .fill(LumenColor.accent)
                        .frame(width: LumenSize.dotLg + 1, height: LumenSize.dotLg + 1)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, LumenSpacing.l)
            .padding(.vertical, LumenSpacing.sm3)
            .frame(minHeight: LumenSize.buttonSm + 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous)
                    .fill(isSelected
                          ? LumenColor.accent.opacity(LumenOpacity.surfaceFill)
                          : LumenColor.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous)
                            .stroke(isSelected ? LumenColor.accent : Color.clear,
                                    lineWidth: LumenSize.strokeMd)
                    )
            )
            .animation(LumenAnimation.quick, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("energy-\(identifier)")
    }
}

#if DEBUG
#Preview {
    Q2EnergyView(vm: .preview, onNext: {}, onBack: {})
        .preferredColorScheme(.dark)
}
#endif
