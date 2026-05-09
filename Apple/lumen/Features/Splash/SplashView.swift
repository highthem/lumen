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
    @State private var charOffset: [CGFloat] = Array(repeating: LumenSpacing.xs, count: SplashView.word.count)
    @State private var subtitleOpacity: Double = 0
    @State private var rootOpacity: Double = 1

    var body: some View {
        GeometryReader { geo in
            let H = geo.size.height
            let W = geo.size.width
            let horizonY = H * 0.6
            let initialHorizonW: CGFloat = LumenSpacing.xxh
            let fullHorizonW = W
            let horizonWidth = initialHorizonW + (fullHorizonW - initialHorizonW) * horizonProgress
            let aubeHeight = H * 0.30 * aubeProgress

            ZStack {
                LumenColor.Splash.earth
                    .ignoresSafeArea()

                // Aube — soft warm halo above the horizon, growing upward
                AubeGradient()
                    .frame(width: W, height: max(0, aubeHeight))
                    .position(x: W / 2, y: horizonY - aubeHeight / 2)
                    .allowsHitTesting(false)

                // Horizon line — 1pt accent rule, centered, animates width
                Rectangle()
                    .fill(LumenColor.accent)
                    .frame(width: horizonWidth, height: LumenSize.hairline)
                    .position(x: W / 2, y: horizonY)

                // "Lumen" — italic serif, character-by-character reveal
                lumenWord
                    .position(x: W / 2, y: horizonY - LumenSpacing.sm2 - LumenSpacing.xl0)

                // Subtitle — "Morning Ritual" italic, fades in below horizon
                Text("Morning Ritual")
                    .lumenFont(.bodySerif)
                    .italic()
                    .foregroundStyle(LumenColor.textPrimary.opacity(subtitleOpacity))
                    .position(x: W / 2, y: horizonY + LumenSpacing.xl2)
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
                    .lumenFont(.wordmark)
                    .italic()
                    .foregroundStyle(LumenColor.textPrimary)
                    .opacity(charOpacity[idx])
                    .offset(y: charOffset[idx])
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Full-motion timeline

    private func playFull() async {
        // Phase 1 — horizon-extend (0 → 400ms)
        withAnimation(LumenAnimation.decelerateLong) {
            horizonProgress = 1
        }

        // Wait until t = 400ms — sunrise starts
        try? await Task.sleep(nanoseconds: LumenDelay.settleNs)
        withAnimation(LumenAnimation.decelerateLong) {
            aubeProgress = 1
        }

        // Wait until t = 600ms — lumen-reveal starts (200ms after sunrise)
        try? await Task.sleep(nanoseconds: LumenDelay.breathNs)
        for idx in 0..<Self.word.count {
            withAnimation(LumenAnimation.quick) {
                charOpacity[idx] = 1
                charOffset[idx] = 0
            }
            // Stagger next char by 60ms
            if idx < Self.word.count - 1 {
                try? await Task.sleep(nanoseconds: LumenDelay.charSlowNs)
            }
        }

        // Wait until t = 1100ms — subtitle fades in
        // We've consumed 0 + 400 + 200 + (4 × 60) = 840ms; sleep the remainder to 1100ms.
        let elapsedAfterChars: UInt64 = LumenDelay.sceneNs + (4 * LumenDelay.charSlowNs)
        let target: UInt64 = LumenDelay.nextSceneNs
        if elapsedAfterChars < target {
            try? await Task.sleep(nanoseconds: target - elapsedAfterChars)
        }
        withAnimation(LumenAnimation.decelerate) {
            subtitleOpacity = LumenOpacity.p60
        }

        // Wait until t = 1400ms — exit-fade
        try? await Task.sleep(nanoseconds: LumenDelay.pauseLongNs)
        withAnimation(LumenAnimation.instant) {
            rootOpacity = 0
        }

        // Wait for exit-fade to finish
        try? await Task.sleep(nanoseconds: LumenDelay.beatNs)
    }

    // MARK: - Reduce-motion fallback (800ms cross-fade)

    private func playReduced() async {
        // 0 → 200ms — hold launch frame (only 80pt horizon, nothing else)
        try? await Task.sleep(nanoseconds: LumenDelay.breathNs)

        // 200 → 500ms — cross-fade in everything
        withAnimation(LumenAnimation.standard) {
            horizonProgress = 1
            aubeProgress = 1
            for idx in 0..<Self.word.count {
                charOpacity[idx] = 1
                charOffset[idx] = 0
            }
            subtitleOpacity = LumenOpacity.p60
        }

        // 500 → 700ms — hold
        try? await Task.sleep(nanoseconds: LumenDelay.exhaleNs)

        // 700 → 800ms — exit-fade
        withAnimation(LumenAnimation.instant) {
            rootOpacity = 0
        }
        try? await Task.sleep(nanoseconds: LumenDelay.beatNs)
    }
}

// MARK: - Aube gradient

private struct AubeGradient: View {
    var body: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: LumenColor.Splash.dawnTop.opacity(LumenOpacity.ring), location: 0.0),
                Gradient.Stop(color: LumenColor.Splash.dawnTop.opacity(LumenOpacity.p32), location: 0.30),
                Gradient.Stop(color: LumenColor.Splash.dawnBottom.opacity(LumenOpacity.p16), location: 0.60),
                Gradient.Stop(color: LumenColor.Splash.dawnBottom.opacity(0), location: 1.0)
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
                endRadius: LumenSize.splashRadial
            )
        )
    }
}

#Preview {
    SplashView(onComplete: {})
        .preferredColorScheme(.dark)
}
