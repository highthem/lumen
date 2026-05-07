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

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        AppleIntelligenceBadge()
        AppleIntelligenceBadge(shimmer: true)
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
