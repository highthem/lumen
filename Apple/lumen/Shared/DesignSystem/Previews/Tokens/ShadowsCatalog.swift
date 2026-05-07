#if DEBUG
import SwiftUI

struct ShadowsCatalog: View {
    private func name(for shadow: LumenShadow) -> String {
        switch shadow {
        case .subtle:                  return "subtle"
        case .elevated:                return "elevated"
        case .liteCard:                return "liteCard"
        case .accentGlow(let active):  return active ? "accentGlow(active: true)" : "accentGlow(active: false)"
        case .alarmTextHalo:           return "alarmTextHalo"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LumenSpacing.xl) {
                ForEach(Array(LumenShadow.allCases.enumerated()), id: \.offset) { _, shadow in
                    VStack(spacing: LumenSpacing.s) {
                        RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous)
                            .fill(LumenColor.bgSecondary)
                            .frame(width: 200, height: 80)
                            .lumenShadow(shadow)
                            .overlay(
                                Text(name(for: shadow))
                                    .lumenFont(.caption)
                                    .foregroundStyle(LumenColor.textPrimary)
                                    .padding(.horizontal, LumenSpacing.s)
                                    .multilineTextAlignment(.center)
                            )
                    }
                }
            }
            .padding(LumenSpacing.xl)
            .frame(maxWidth: .infinity)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Shadows")
    }
}

#Preview("Light") {
    NavigationStack { ShadowsCatalog() }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack { ShadowsCatalog() }
        .preferredColorScheme(.dark)
}
#endif
