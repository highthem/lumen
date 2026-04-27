import SwiftUI

struct LumenSegmentedControl<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                } label: {
                    Text(label(option))
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                        .foregroundStyle(isSelected ? LumenColor.textPrimary : LumenColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            isSelected
                                ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(LumenColor.bgPrimary)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(LumenColor.bgTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
