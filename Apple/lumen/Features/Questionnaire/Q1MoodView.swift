import SwiftUI

struct Q1MoodView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    private static let entries: [(label: String, sub: String)] = [
        ("enfoui",     "pesant, lent à se lever"),
        ("fragile",    "le souffle est court"),
        ("posé",       "le souffle est régulier"),
        ("vif",        "présent, alerte"),
        ("rayonnant",  "plein, ouvert"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
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

            VStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { level in
                    let entry = Self.entries[level]
                    MoodChoiceRow(
                        level: level,
                        label: entry.label,
                        sub: entry.sub,
                        isSelected: vm.moodLevel == level,
                        action: {
                            vm.moodLevel = level
                            vm.moodTag = entry.label
                        }
                    )
                }
            }

            Spacer(minLength: 0)

            FooterRow(
                backTitle: "Retour",
                nextTitle: "Suivant",
                isNextEnabled: vm.moodTag != nil || vm.moodLevel != 2,
                onBack: onBack,
                onNext: onNext,
                showBack: false
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, 28)
        .padding(.bottom, LumenSpacing.l)
    }
}
