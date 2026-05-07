import SwiftUI

private enum SegmentedControlLayout {
    static let segmentPaddingV: CGFloat = 7
}

struct LumenSegmentedControl<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: LumenSpacing.xxs) {
            ForEach(options) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                } label: {
                    Text(label(option))
                        .lumenFont(.footnote)
                        .fontWeight(isSelected ? .medium : .regular)
                        .foregroundStyle(isSelected ? LumenColor.textPrimary : LumenColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SegmentedControlLayout.segmentPaddingV)
                        .background(
                            isSelected
                                ? RoundedRectangle(cornerRadius: LumenRadius.s, style: .continuous)
                                    .fill(LumenColor.bgPrimary)
                                    .lumenShadow(.subtle)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(LumenSpacing.xxs)
        .background(LumenColor.bgTertiary)
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.s, style: .continuous))
    }
}

#if DEBUG
private struct SegmentedControlPreviewOption: Hashable, Identifiable {
    let id: String
    var label: String { id }
}

#Preview {
    @Previewable @State var selection = SegmentedControlPreviewOption(id: "Semaine")
    let options: [SegmentedControlPreviewOption] = [
        .init(id: "Jour"), .init(id: "Semaine"), .init(id: "Mois")
    ]
    LumenSegmentedControl(options: options, selection: $selection, label: { $0.label })
        .padding(LumenSpacing.l)
        .background(LumenColor.bgPrimary)
}
#endif
