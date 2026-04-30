import SwiftUI

/// First-run splash — plays once per cold launch then hands off via `onComplete`.
///
/// Timeline (matches `05-splash.html`):
///   0    → 400 ms  · horizon-extend (.easeOut)         — line grows 80pt → full width
///   400  → 800 ms  · sunrise-rise (.easeInOut)         — aube halo grows 0 → 30% screen height
///   600  → ~1100 ms · lumen-reveal (linear, per-char)   — 5 chars × 60ms cadence, soft 180ms fade
///   1100 → 1400 ms · subtitle-fade (.easeOut)          — "Bonjour." opacity 0 → 0.6
///   1400 → 1500 ms · exit-fade (.easeIn)               — everything → 0
///
/// Reduce Motion fallback runs 800 ms total: 200 ms hold launch frame, 300 ms cross-fade in,
/// 200 ms hold, 100 ms exit. No char-by-char, no spring, no repeat.
struct SplashView: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Word characters
    private static let word: [Character] = Array("Lumen")

    // Animatable state
    @State private var horizonProgress: CGFloat = 0   // 0 → 1 (width 80pt → full)
    @State private var aubeProgress: CGFloat = 0      // 0 → 1 (height 0 → 30%)
    @State private var charOpacity: [Double] = Array(repeating: 0, count: SplashView.word.count)
    @State private var charOffset: [CGFloat] = Array(repeating: 4, count: SplashView.word.count)
    @State private var subtitleOpacity: Double = 0
    @State private var rootOpacity: Double = 1

    var body: some View {
        GeometryReader { geo in
            let H = geo.size.height
            let W = geo.size.width
            let horizonY = H * 0.6
            let initialHorizonW: CGFloat = 80
            let fullHorizonW = W
            let horizonWidth = initialHorizonW + (fullHorizonW - initialHorizonW) * horizonProgress
            let aubeHeight = H * 0.30 * aubeProgress

            ZStack {
                Color(red: 0x0F/255, green: 0x0D/255, blue: 0x0B/255)
                    .ignoresSafeArea()

                // Aube — soft warm halo above the horizon, growing upward
                AubeGradient()
                    .frame(width: W, height: max(0, aubeHeight))
                    .position(x: W / 2, y: horizonY - aubeHeight / 2)
                    .allowsHitTesting(false)

                // Horizon line — 1pt accent rule, centered, animates width
                Rectangle()
                    .fill(LumenColor.accent)
                    .frame(width: horizonWidth, height: 1)
                    .position(x: W / 2, y: horizonY)

                // "Lumen" — italic serif, character-by-character reveal
                lumenWord
                    .position(x: W / 2, y: horizonY - 12 - 28)

                // Subtitle — "Bonjour." italic, fades in below horizon
                Text(localizedGreeting)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(LumenColor.textPrimary.opacity(subtitleOpacity))
                    .position(x: W / 2, y: horizonY + 36)
            }
            .opacity(rootOpacity)
        }
        .ignoresSafeArea()
        .task {
            if reduceMotion {
                await playReduced()
            } else {
                await playFull()
            }
            onComplete()
        }
    }

    // MARK: - Lumen word reveal

    private var lumenWord: some View {
        HStack(spacing: 0) {
            ForEach(Array(Self.word.enumerated()), id: \.offset) { idx, ch in
                Text(String(ch))
                    .font(.system(size: 56, weight: .regular, design: .serif))
                    .italic()
                    .tracking(-0.56)
                    .foregroundStyle(LumenColor.textPrimary)
                    .opacity(charOpacity[idx])
                    .offset(y: charOffset[idx])
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Localized greeting

    private var localizedGreeting: String {
        let lang = Locale.preferredLanguages.first ?? "fr"
        return lang.hasPrefix("fr") ? "Bonjour." : "Hello."
    }

    // MARK: - Full-motion timeline

    private func playFull() async {
        // Phase 1 — horizon-extend (0 → 400ms)
        withAnimation(.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.40)) {
            horizonProgress = 1
        }

        // Wait until t = 400ms — sunrise starts
        try? await Task.sleep(nanoseconds: 400_000_000)
        withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.40)) {
            aubeProgress = 1
        }

        // Wait until t = 600ms — lumen-reveal starts (200ms after sunrise)
        try? await Task.sleep(nanoseconds: 200_000_000)
        for idx in 0..<Self.word.count {
            withAnimation(.linear(duration: 0.18)) {
                charOpacity[idx] = 1
                charOffset[idx] = 0
            }
            // Stagger next char by 60ms
            if idx < Self.word.count - 1 {
                try? await Task.sleep(nanoseconds: 60_000_000)
            }
        }

        // Wait until t = 1100ms — subtitle fades in
        // We've consumed 0 + 400 + 200 + (4 × 60) = 840ms; sleep the remainder to 1100ms.
        let elapsedAfterChars: UInt64 = 600_000_000 + (4 * 60_000_000)
        let target: UInt64 = 1_100_000_000
        if elapsedAfterChars < target {
            try? await Task.sleep(nanoseconds: target - elapsedAfterChars)
        }
        withAnimation(.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.30)) {
            subtitleOpacity = 0.6
        }

        // Wait until t = 1400ms — exit-fade
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.10)) {
            rootOpacity = 0
        }

        // Wait for exit-fade to finish
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    // MARK: - Reduce-motion fallback (800ms cross-fade)

    private func playReduced() async {
        // 0 → 200ms — hold launch frame (only 80pt horizon, nothing else)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // 200 → 500ms — cross-fade in everything
        withAnimation(.easeOut(duration: 0.30)) {
            horizonProgress = 1
            aubeProgress = 1
            for idx in 0..<Self.word.count {
                charOpacity[idx] = 1
                charOffset[idx] = 0
            }
            subtitleOpacity = 0.6
        }

        // 500 → 700ms — hold
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 700 → 800ms — exit-fade
        withAnimation(.easeIn(duration: 0.10)) {
            rootOpacity = 0
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}

// MARK: - Aube gradient

private struct AubeGradient: View {
    var body: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 0xE8/255, green: 0xC3/255, blue: 0x9E/255).opacity(0.55), location: 0.0),
                Gradient.Stop(color: Color(red: 0xE8/255, green: 0xC3/255, blue: 0x9E/255).opacity(0.32), location: 0.30),
                Gradient.Stop(color: Color(red: 0xA6/255, green: 0x85/255, blue: 0x66/255).opacity(0.16), location: 0.60),
                Gradient.Stop(color: Color(red: 0xA6/255, green: 0x85/255, blue: 0x66/255).opacity(0.0),  location: 1.0)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
        .mask(
            RadialGradient(
                stops: [
                    Gradient.Stop(color: .black, location: 0.30),
                    Gradient.Stop(color: .black.opacity(0), location: 0.80)
                ],
                center: UnitPoint(x: 0.5, y: 1.0),
                startRadius: 0,
                endRadius: 320
            )
        )
    }
}

#Preview {
    SplashView(onComplete: {})
        .preferredColorScheme(.dark)
}
