import SwiftUI

struct Q3PriorityView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var current: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            ProgressDots4(current: 2)

            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                Eyebrow("03 / 04 · Priorité")
                Text("Sur quoi tu veux\nposer l'attention ?")
                    .lumenFont(.title1)
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CardDeck(
                items: PriorityCategory.allCases,
                current: $current,
                selected: Binding(
                    get: { vm.priorityCategory },
                    set: { vm.priorityCategory = $0 }
                ),
                cardHeight: LumenSize.cardPriority
            ) { item, selected in
                priorityCard(category: item, selected: selected)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, LumenSpacing.s)

            Spacer(minLength: LumenSpacing.s)

            FooterRow(
                backTitle: "Retour",
                nextTitle: "Suivant",
                isNextEnabled: vm.priorityCategory != nil,
                onBack: onBack,
                onNext: onNext
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, LumenSpacing.xl0)
        .padding(.bottom, LumenSpacing.l)
        .onAppear {
            // Sync `current` to the persisted selection if the user navigates back.
            if let cat = vm.priorityCategory,
               let idx = PriorityCategory.allCases.firstIndex(of: cat) {
                current = idx
            }
        }
    }

    private func priorityCard(category: PriorityCategory, selected: Bool) -> some View {
        Button {
            vm.priorityCategory = (vm.priorityCategory == category) ? nil : category
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // ─ Top: rounded-square icon chip
                ZStack {
                    RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                        .fill(LumenColor.accent.opacity(LumenOpacity.surfaceFill))
                    PriorityIcon(category: category, size: LumenSize.iconLg)
                        .foregroundStyle(LumenColor.accent)
                }
                .frame(width: LumenSize.halfMod, height: LumenSize.halfMod)

                Spacer(minLength: 0)

                // ─ Middle: name + prompt
                VStack(alignment: .leading, spacing: LumenSpacing.sm2) {
                    Text("\(category.displayName).")
                        .lumenFont(.synthesisHero)
                        .italic()
                        .foregroundStyle(selected ? LumenColor.accent : LumenColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(category.prompt)
                        .lumenFont(.bodySerifSm)
                        .italic()
                        .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.p78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                // ─ Bottom: tap state
                Text(selected ? "● Choisi" : "Tap pour choisir")
                    .lumenFont(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(selected ? LumenColor.accent : LumenColor.textTertiary)
                    .opacity(selected ? 1.0 : LumenOpacity.muted)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal, LumenSpacing.lp)
            .padding(.vertical, LumenSpacing.l2)
            .frame(height: LumenSize.cardPriority, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous)
                    .fill(LumenColor.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous)
                            .stroke(selected ? LumenColor.accent : Color.clear, lineWidth: LumenSize.strokeMd)
                    )
                    .lumenShadow(.elevated)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("priority-\(category.rawValue)")
    }
}
