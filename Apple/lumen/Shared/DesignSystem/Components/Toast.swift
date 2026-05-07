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

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        Toast(message: "Synthèse prête à écouter")
        Toast(message: "Sans accent dot", accentDot: false)
    }
    .padding(LumenSpacing.l)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LumenColor.bgPrimary)
}
#endif
