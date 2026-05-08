import SwiftUI

/// Q2 hero — a breathing orb whose size, halo count, and pulse cadence
/// scale with the chosen energy level. Mirrors `screens-flow.jsx` Q2Energy
/// (V11 iter 19+): contained shape with concentric aura, no chromatic
/// background — the differentiator from Q1 is *form*, not color.
struct EnergyOrb: View {
    let level: Int   // 0…4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    private var clamped: Int { max(0, min(4, level)) }

    private var orbSize: CGFloat {
        LumenSize.energyOrbMin + CGFloat(clamped) * LumenSize.energyOrbStep
    }
    private var auraCount: Int { clamped + 1 }
    private var auraBase: Double { 0.08 + Double(clamped) * 0.05 }
    private var period: Double { 2.4 - Double(clamped) * 0.25 }
    private var shadowY: CGFloat { 10 + CGFloat(clamped) * 4 }
    private var shadowBlur: CGFloat { 30 + CGFloat(clamped) * 10 }
    private var shadowOpacity: Double { 0.15 + Double(clamped) * 0.05 }

    var body: some View {
        ZStack {
            ForEach(0..<auraCount, id: \.self) { i in
                halo(index: i)
            }
            core
        }
        .frame(width: LumenSize.energyOrbFrame, height: LumenSize.energyOrbFrame)
        .animation(.easeInOut(duration: 0.4), value: clamped)
        .onAppear { pulse = true }
        .accessibilityElement()
        .accessibilityLabel("Énergie niveau \(clamped + 1) sur 5")
    }

    private func halo(index i: Int) -> some View {
        let ringSize = orbSize + CGFloat(i + 1) * 18
        let opacity = max(0.05, auraBase - Double(i) * 0.04)
        let scale: CGFloat = reduceMotion ? 1.0 : (pulse ? 1.04 : 1.0)
        let anim: Animation? = reduceMotion
            ? nil
            : .easeInOut(duration: period)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.18)
        return Circle()
            .stroke(LumenColor.accent, lineWidth: LumenSize.hairline)
            .opacity(opacity)
            .frame(width: ringSize, height: ringSize)
            .scaleEffect(scale)
            .animation(anim, value: pulse)
    }

    private var core: some View {
        let scale: CGFloat = reduceMotion ? 1.0 : (pulse ? 1.02 : 1.0)
        let anim: Animation? = reduceMotion
            ? nil
            : .easeInOut(duration: period).repeatForever(autoreverses: true)
        let gradient = RadialGradient(
            colors: [LumenColor.accent, LumenColor.OrbCore.mid, LumenColor.OrbCore.deep],
            center: UnitPoint(x: 0.35, y: 0.30),
            startRadius: 0,
            endRadius: orbSize
        )
        return Circle()
            .fill(gradient)
            .frame(width: orbSize, height: orbSize)
            .shadow(
                color: LumenColor.accent.opacity(shadowOpacity),
                radius: shadowBlur,
                x: 0,
                y: shadowY
            )
            .scaleEffect(scale)
            .animation(anim, value: pulse)
    }
}

#if DEBUG
#Preview("Levels 0…4") {
    HStack(spacing: 24) {
        ForEach(0..<5, id: \.self) { level in
            VStack(spacing: 8) {
                EnergyOrb(level: level)
                    .scaleEffect(0.5)
                    .frame(width: 120, height: 120)
                Text("level \(level)")
                    .lumenFont(.caption)
                    .foregroundStyle(LumenColor.textSecondary)
            }
        }
    }
    .padding()
    .background(LumenColor.bgPrimary)
}

#Preview("Level 3 — single") {
    EnergyOrb(level: 3)
        .padding()
        .background(LumenColor.bgPrimary)
}
#endif
