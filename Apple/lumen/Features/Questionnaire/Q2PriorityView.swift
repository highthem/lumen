import SwiftUI

struct Q2PriorityView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            ProgressDots4(current: 1)

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("02 / 04 · Priorité")
                Text("Qu'est-ce qui\ncompte aujourd'hui ?")
                    .font(.system(size: 30, weight: .medium, design: .serif))
                    .tracking(-0.45)
                    .lineSpacing(-2)
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Wrap chips horizontally
            FlowLayout(spacing: 8) {
                ForEach(DashboardCategory.allCases, id: \.self) { cat in
                    Chip(
                        label: cat.displayName,
                        isSelected: vm.priorityCategory == cat
                    ) {
                        vm.priorityCategory = cat
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("Précise si tu veux")

                ZStack(alignment: .topLeading) {
                    if vm.priorityNote.isEmpty {
                        Text("optionnel")
                            .font(.system(size: 15))
                            .foregroundStyle(LumenColor.textTertiary)
                            .padding(.top, 14)
                            .padding(.leading, 18)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $vm.priorityNote)
                        .font(.system(size: 15))
                        .foregroundStyle(LumenColor.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(minHeight: 80, maxHeight: 80)
                        .scrollContentBackground(.hidden)
                        .background(LumenColor.bgSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(LumenColor.divider, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

// Simple flow / wrap layout — reuses the design system Chip without a grid.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let arranged = arrange(subviews: subviews, in: width)
        return CGSize(width: width, height: arranged.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arranged = arrange(subviews: subviews, in: bounds.width)
        for (subview, point) in zip(subviews, arranged.points) {
            let size = subview.sizeThatFits(.unspecified)
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(size))
        }
    }

    private func arrange(subviews: Subviews, in width: CGFloat) -> (points: [CGPoint], height: CGFloat) {
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (points, y + rowHeight)
    }
}
