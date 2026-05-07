import SwiftUI

/// V5 unified footer: ghost "Retour" left + primary CTA right (full-width remaining), 56pt height.
struct FooterRow: View {
    let backTitle: String
    let nextTitle: String
    let isNextEnabled: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    var showBack: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            if showBack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text(backTitle)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(LumenColor.textSecondary)
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                }
                .buttonStyle(.plain)
            }

            Button(action: onNext) {
                Text(nextTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(LumenColor.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                            .fill(LumenColor.accent)
                    )
                    .opacity(isNextEnabled ? 1.0 : 0.55)
            }
            .buttonStyle(.plain)
            .disabled(!isNextEnabled)
        }
        .frame(height: 56)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        FooterRow(backTitle: "Retour", nextTitle: "Continuer", isNextEnabled: true,  onBack: {}, onNext: {})
        FooterRow(backTitle: "Retour", nextTitle: "Continuer", isNextEnabled: false, onBack: {}, onNext: {})
        FooterRow(backTitle: "Retour", nextTitle: "Commencer", isNextEnabled: true,  onBack: {}, onNext: {}, showBack: false)
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
