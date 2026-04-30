import SwiftUI

struct Q1MoodView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    private static let tags: [String] = ["enfoui", "fragile", "posé", "vif", "rayonnant"]

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            ProgressDots4(current: 0)

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("01 / 04 · Ressenti")
                Text("Comment tu\nte sens ?")
                    .font(.system(size: 30, weight: .medium, design: .serif))
                    .tracking(-0.45)
                    .lineSpacing(-2)
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(spacing: 14) {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<5, id: \.self) { level in
                        sunButton(level: level)
                    }
                }

                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { level in
                        Text(Self.tags[level])
                            .font(.system(size: 13, design: .serif))
                            .italic()
                            .tracking(-0.065)
                            .foregroundStyle(
                                vm.moodLevel == level
                                ? LumenColor.accent
                                : LumenColor.textPrimary.opacity(0.45)
                            )
                            .frame(maxWidth: .infinity)
                            .animation(.easeOut(duration: 0.25), value: vm.moodLevel)
                    }
                }
            }

            Spacer(minLength: 0)

            FooterRow(
                backTitle: "Retour",
                nextTitle: "Suivant",
                isNextEnabled: vm.moodTag != nil,
                onBack: onBack,
                onNext: onNext,
                showBack: false
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, 28)
        .padding(.bottom, LumenSpacing.l)
    }

    @ViewBuilder
    private func sunButton(level: Int) -> some View {
        let isSelected = vm.moodLevel == level
        Button {
            vm.moodLevel = level
            vm.moodTag = Self.tags[level]
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .stroke(LumenColor.accent.opacity(0.35), lineWidth: 1)
                        .frame(width: 68, height: 68)
                }
                Circle()
                    .fill(Color.clear)
                    .frame(width: 56, height: 56)
                    .overlay(
                        SunGlyph(level: level, size: 36, color: LumenColor.accent)
                    )
            }
            .frame(maxWidth: .infinity)
            .opacity(isSelected ? 1.0 : 0.55)
            .scaleEffect(isSelected ? 1.10 : 1.0)
            .animation(.easeOut(duration: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
