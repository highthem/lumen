import SwiftUI

struct Q2PriorityView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var current: Int = 0

    private static let prompts: [DashboardCategory: String] = [
        .energy:    "Une priorité d'énergie aujourd'hui ?",
        .intention: "Une intention pour ce matin ?",
        .body:      "Quelque chose pour ton corps ?",
        .relations: "Une relation à soigner ?",
        .work:      "Une priorité de travail ?",
        .gratitude: "Quelque chose te tient à cœur ?"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
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

            CardDeck(
                items: DashboardCategory.allCases,
                current: $current,
                selected: Binding(
                    get: { vm.priorityCategory },
                    set: { vm.priorityCategory = $0 }
                )
            ) { item, selected in
                priorityCard(category: item, selected: selected)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, LumenSpacing.s)

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
        .onAppear {
            // Sync `current` to the persisted selection if the user navigates back.
            if let cat = vm.priorityCategory,
               let idx = DashboardCategory.allCases.firstIndex(of: cat) {
                current = idx
            }
        }
    }

    private func priorityCard(category: DashboardCategory, selected: Bool) -> some View {
        Button {
            vm.priorityCategory = (vm.priorityCategory == category) ? nil : category
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                PriorityIcon(category: category, size: 26)
                    .foregroundStyle(LumenColor.accent)

                Text("\(category.displayName).")
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .tracking(-0.39)
                    .foregroundStyle(LumenColor.textPrimary)

                Text(Self.prompts[category] ?? "")
                    .font(.system(size: 14))
                    .foregroundStyle(LumenColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text(selected ? "● Choisi" : "Tap pour choisir")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.96)
                    .textCase(.uppercase)
                    .foregroundStyle(selected ? LumenColor.accent : LumenColor.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .frame(height: 280)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LumenColor.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(selected ? LumenColor.accent : LumenColor.divider, lineWidth: selected ? 1.5 : 1)
                    )
                    .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}
