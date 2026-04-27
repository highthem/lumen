import SwiftUI

struct PriorityChoiceCard: View {
    let category: DashboardCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                PriorityIcon(category: category, size: 22)
                    .foregroundStyle(isSelected ? LumenColor.bgPrimary : LumenColor.accent)
                    .frame(width: 22, height: 22)

                Text(category.displayName)
                    .font(.system(size: 17, weight: .medium))
                    .tracking(-0.085)
                    .foregroundStyle(isSelected ? LumenColor.bgPrimary : LumenColor.textPrimary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                    .fill(isSelected ? LumenColor.accent : LumenColor.bgSecondary)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}
