import SwiftUI

/// Bento Énergie card: eyebrow + (mini breathing orb + serif italic level
/// name + numeric level caption). JSX reference: `screens-shell.jsx:422–455`.
struct EnergyCard: View {
    let energy: EnergyLevel?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Énergie")
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: LumenSpacing.sm) {
                    BreathingOrb(size: .mini)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(displayValue)
                            .font(.system(size: 19, weight: .medium, design: .serif))
                            .italic()
                            .tracking(-0.005 * 19)
                            .foregroundStyle(LumenColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let energy {
                            Text("niveau \(energy.numericLevel + 1)/5")
                                .font(.system(size: 11))
                                .foregroundStyle(LumenColor.textTertiary)
                        }
                    }
                }
            }
            .padding(LumenSpacing.m)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LumenColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard-card-energy")
    }

    private var displayValue: String {
        guard let energy else { return "non renseigné" }
        return energy.displayName.lowercased()
    }
}

private extension EnergyLevel {
    /// 0…4 mapping mirroring `EnergyLevel` cases — used for the numeric
    /// "niveau N/5" subtitle on the post-rituel card.
    var numericLevel: Int {
        switch self {
        case .flat: return 0
        case .low: return 1
        case .medium: return 2
        case .charged: return 3
        case .top: return 4
        }
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 10) {
        EnergyCard(energy: .charged, onTap: {})
        EnergyCard(energy: nil, onTap: {})
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
