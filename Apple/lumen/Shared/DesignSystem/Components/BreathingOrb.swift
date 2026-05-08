import SwiftUI

/// Sun-rising orb used by the Idle hero card (`.hero` size) and the Énergie
/// post-rituel card (`.mini` size). Three concentric stroked rings expand
/// and fade out forever; a center radial-gradient disc pulses in scale.
///
/// JSX reference: `Design/designs/screens/screens-shell.jsx:218–249` (hero)
/// and `:434–449` (mini). All numeric values mirror the JSX verbatim.
struct BreathingOrb: View {
    enum Size: Sendable {
        case hero   // 220×130 frame, 110pt center disc rising from below
        case mini   // 36×36 frame, in-card energy badge
    }

    let size: Size

    @State private var pulse: Bool = false

    private static let palette: [Color] = [
        Color(lumenHex: 0xF5D9B0),
        Color(lumenHex: 0xE8C39E),  // accent
        Color(lumenHex: 0x7A5934)
    ]

    var body: some View {
        switch size {
        case .hero: heroBody
        case .mini: miniBody
        }
    }

    // MARK: - Hero variant (Idle hero card)

    private var heroBody: some View {
        ZStack(alignment: .bottom) {
            // 3 stroked breathing rings, growing from below the disc
            ForEach(0..<3, id: \.self) { i in
                let ringSize: CGFloat = 110 + CGFloat(i) * 26
                Circle()
                    .stroke(LumenColor.accent, lineWidth: 1)
                    .frame(width: ringSize, height: ringSize)
                    .opacity(pulse ? 0 : (0.18 - Double(i) * 0.05))
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .offset(y: ringSize / 2)
                    .animation(
                        .easeInOut(duration: 2.6 + Double(i) * 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
                        value: pulse
                    )
            }
            // Center disc, half clipped at the horizon line
            Circle()
                .fill(
                    RadialGradient(
                        colors: Self.palette,
                        center: UnitPoint(x: 0.35, y: 0.30),
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 110, height: 110)
                .shadow(color: LumenColor.accent.opacity(0.35), radius: 20, y: -8)
                .scaleEffect(pulse ? 1.04 : 1.0)
                .offset(y: 55)
                .animation(
                    .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                    value: pulse
                )
        }
        .frame(width: 220, height: 130)
        .clipped()
        .accessibilityHidden(true)
        .onAppear { pulse = true }
    }

    // MARK: - Mini variant (Énergie card)

    private var miniBody: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let inset: CGFloat = -CGFloat(i) * 4
                Circle()
                    .stroke(LumenColor.accent, lineWidth: 1)
                    .padding(inset)
                    .opacity(0.18 - Double(i) * 0.05)
            }
            Circle()
                .fill(
                    RadialGradient(
                        colors: Self.palette,
                        center: UnitPoint(x: 0.35, y: 0.30),
                        startRadius: 0,
                        endRadius: 22
                    )
                )
                .padding(4)
                .scaleEffect(pulse ? 1.04 : 1.0)
                .animation(
                    .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                    value: pulse
                )
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
        .onAppear { pulse = true }
    }
}

#if DEBUG
#Preview("Hero") {
    BreathingOrb(size: .hero)
        .padding(LumenSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LumenColor.bgPrimary)
}

#Preview("Mini") {
    BreathingOrb(size: .mini)
        .padding(LumenSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LumenColor.bgPrimary)
}
#endif
