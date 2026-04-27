import SwiftUI

struct MoodChoiceRow: View {
    let level: Int
    let label: String
    let sub: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                ZStack {
                    SunGlyph(level: level, size: 28, color: LumenColor.accent)
                }
                .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .tracking(-0.22)
                        .foregroundStyle(LumenColor.textPrimary)
                    if isSelected {
                        Text(sub)
                            .font(.system(size: 13, design: .serif))
                            .italic()
                            .foregroundStyle(LumenColor.textSecondary)
                            .lineLimit(1)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Text("·")
                        .font(.system(size: 20, design: .serif))
                        .italic()
                        .foregroundStyle(LumenColor.accent)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(minHeight: 72, alignment: .center)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                    .fill(isSelected ? LumenColor.accent.opacity(0.10) : LumenColor.bgSecondary)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.22), value: isSelected)
    }
}
