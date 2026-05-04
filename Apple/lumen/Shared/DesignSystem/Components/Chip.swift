import SwiftUI

struct Chip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    private static let paddingV: CGFloat = 7
    private static let paddingH: CGFloat = 14

    var body: some View {
        Button(action: action) {
            Text(label)
                .lumenFont(.chipLabel)
                .foregroundStyle(isSelected ? LumenColor.bgPrimary : LumenColor.textSecondary)
                .padding(.vertical, Self.paddingV)
                .padding(.horizontal, Self.paddingH)
                .background(isSelected ? LumenColor.accent : LumenColor.bgTertiary)
                .clipShape(RoundedRectangle(cornerRadius: LumenRadius.s, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
