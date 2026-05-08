import SwiftUI

struct AppleIntelligenceBadge: View {
    var shimmer: Bool = false

    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        Text("APPLE INTELLIGENCE")
            .font(.system(size: 11, weight: .regular))
            .tracking(11 * 0.14)
            .foregroundStyle(LumenColor.accent)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(shimmerBackground)
            .overlay(
                RoundedRectangle(cornerRadius: LumenRadius.round, style: .continuous)
                    .strokeBorder(LumenColor.accent.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.round, style: .continuous))
            .onAppear {
                guard shimmer else { return }
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }
    }

    @ViewBuilder
    private var shimmerBackground: some View {
        if shimmer {
            LinearGradient(
                stops: [
                    .init(color: LumenColor.accent.opacity(0.05), location: shimmerPhase - 0.3),
                    .init(color: LumenColor.accent.opacity(0.15), location: shimmerPhase),
                    .init(color: LumenColor.accent.opacity(0.05), location: shimmerPhase + 0.3)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            LumenColor.accent.opacity(0.05)
        }
    }
}

/// Generic provider badge for the synthesis screen. Renders the right
/// chip in the top-right slot per the V11 mocks: Cloud has no badge,
/// Apple Intelligence shows the shimmering pill, Queued shows an orange
/// dot + "EN ATTENTE · PAS DE RÉSEAU".
struct ProviderBadge: View {
    enum Kind { case cloud, appleIntelligence, queued }

    let kind: Kind

    var body: some View {
        switch kind {
        case .cloud:
            EmptyView()
        case .appleIntelligence:
            AppleIntelligenceBadge(shimmer: true)
        case .queued:
            HStack(spacing: 6) {
                Circle()
                    .fill(LumenColor.warning)
                    .frame(width: 6, height: 6)
                Text("EN ATTENTE · PAS DE RÉSEAU")
                    .font(.system(size: 11, weight: .regular))
                    .tracking(11 * 0.14)
                    .foregroundStyle(LumenColor.textSecondary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(LumenColor.warning.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: LumenRadius.round, style: .continuous)
                    .strokeBorder(LumenColor.warning.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.round, style: .continuous))
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        AppleIntelligenceBadge()
        AppleIntelligenceBadge(shimmer: true)
        ProviderBadge(kind: .queued)
        ProviderBadge(kind: .cloud)
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
