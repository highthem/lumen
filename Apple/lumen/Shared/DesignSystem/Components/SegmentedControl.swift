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
