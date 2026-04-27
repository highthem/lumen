import SwiftUI

struct Chip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(isSelected ? LumenColor.bgPrimary : LumenColor.textSecondary)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(isSelected ? LumenColor.accent : LumenColor.bgTertiary)
                .clipShape(RoundedRectangle(cornerRadius: LumenRadius.s, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
