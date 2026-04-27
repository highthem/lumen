import SwiftUI

struct Toast: View {
    let message: String
    var accentDot: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            if accentDot {
                Circle()
                    .fill(LumenColor.accent)
                    .frame(width: 6, height: 6)
            }
            Text(message)
                .lumenFont(.footnote)
                .foregroundStyle(LumenColor.textPrimary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(LumenColor.bgTertiary)
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
    }
}
