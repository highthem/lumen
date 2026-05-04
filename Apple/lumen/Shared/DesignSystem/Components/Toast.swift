import SwiftUI

struct Toast: View {
    let message: String
    var accentDot: Bool = true

    var body: some View {
        HStack(spacing: LumenSpacing.s) {
            if accentDot {
                Circle()
                    .fill(LumenColor.accent)
                    .frame(width: LumenSize.dotMd, height: LumenSize.dotMd)
            }
            Text(message)
                .lumenFont(.footnote)
                .foregroundStyle(LumenColor.textPrimary)
        }
        .padding(.vertical, LumenSpacing.sm2)
        .padding(.horizontal, LumenSpacing.m)
        .background(LumenColor.bgTertiary)
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
    }
}
