import SwiftUI

struct Q2PriorityView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ProgressDots4(current: 1)

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("02 / 04 · Priorité")
                Text("Sur quoi tu veux\nposer l'attention ?")
                    .font(.system(size: 30, weight: .medium, design: .serif))
                    .tracking(-0.45)
                    .lineSpacing(-2)
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(DashboardCategory.allCases, id: \.self) { cat in
                    PriorityChoiceCard(
                        category: cat,
                        isSelected: vm.priorityCategory == cat,
                        action: { vm.priorityCategory = cat }
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("PRÉCISE SI TU VEUX")
                    .font(.system(size: 11, weight: .regular))
                    .tracking(11 * 0.22)
                    .foregroundStyle(LumenColor.textTertiary)

                ZStack(alignment: .topLeading) {
                    if vm.priorityNote.isEmpty {
                        Text("Une phrase courte, ou rien.")
                            .font(.system(size: 15, design: .serif))
                            .italic()
                            .foregroundStyle(LumenColor.textTertiary)
                            .padding(.top, 14)
                            .padding(.leading, 18)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $vm.priorityNote)
                        .font(.system(size: 15, design: .serif))
                        .italic()
                        .foregroundStyle(LumenColor.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(minHeight: 64, maxHeight: 64)
                        .scrollContentBackground(.hidden)
                        .background(LumenColor.bgSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.top, 6)

            Spacer(minLength: 8)

            FooterRow(
                backTitle: "Retour",
                nextTitle: "Suivant",
                isNextEnabled: vm.priorityCategory != nil,
                onBack: onBack,
                onNext: onNext
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, 28)
        .padding(.bottom, LumenSpacing.l)
    }
}
