import SwiftUI

/// V8 mic CTA: 120pt circle, real microphone glyph.
/// - idle:        1.5pt accent border, 12% accent fill, mic outline glyph (42pt)
/// - listening:   solid accent fill, 4s breathing scale, two outward concentric ring waves
/// - transcribed: thin accent border, faded mic glyph
struct MicCTA: View {
    let isListening: Bool
    let onPressDown: () -> Void
    let onPressUp: () -> Void
    var accessibilityID: String = "mic-button"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false
    @State private var breathScale: CGFloat = 1.0
    @State private var ring1Scale: CGFloat = MicCTA.ringStartScale
    @State private var ring1Opacity: Double = LumenOpacity.ring
    @State private var ring2Scale: CGFloat = MicCTA.ringStartScale
    @State private var ring2Opacity: Double = LumenOpacity.ring

    private static let ringStartScale: CGFloat = 0.95
    private static let ringEndScale: CGFloat = 1.45
    private static let breathTargetScale: CGFloat = 1.03
    private static let glyphSize: CGFloat = 42
    private static let ringInset: CGFloat = 20
    private static let outerInset: CGFloat = 40
    private static let breathCycle: TimeInterval = LumenDuration.breath
    private let buttonSize: CGFloat = LumenSize.micLg

    var body: some View {
        ZStack {
            // Listening: two concentric ring waves expanding outward
            if isListening {
                ringWave(scale: ring1Scale, opacity: ring1Opacity)
                ringWave(scale: ring2Scale, opacity: ring2Opacity)
            }

            // Main button
            ZStack {
                if isListening {
                    Circle().fill(LumenColor.accent)
                } else {
                    Circle()
                        .fill(LumenColor.accent.opacity(LumenOpacity.surfaceFill))
                        .overlay(
                            Circle().strokeBorder(LumenColor.accent, lineWidth: LumenSize.strokeMd)
                        )
                }

                MicGlyph(size: Self.glyphSize, color: isListening ? LumenColor.bgPrimary : LumenColor.accent)
            }
            .frame(width: buttonSize, height: buttonSize)
            .scaleEffect(isListening && !reduceMotion ? breathScale : 1.0)
            .lumenShadow(.accentGlow(active: isListening))
        }
        .frame(width: buttonSize + Self.outerInset, height: buttonSize + Self.outerInset)
        .contentShape(Circle())
        .onChange(of: isListening) { _, listening in
            if listening && !reduceMotion {
                withAnimation(.easeInOut(duration: Self.breathCycle).repeatForever(autoreverses: true)) {
                    breathScale = Self.breathTargetScale
                }
                animateRings()
            } else {
                breathScale = 1.0
                ring1Scale = Self.ringStartScale; ring1Opacity = LumenOpacity.ring
                ring2Scale = Self.ringStartScale; ring2Opacity = LumenOpacity.ring
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        pressed = true
                        onPressDown()
                    }
                }
                .onEnded { _ in
                    if pressed {
                        pressed = false
                        onPressUp()
                    }
                }
        )
        .accessibilityElement()
        .accessibilityIdentifier(accessibilityID)
        .accessibilityLabel(isListening ? "Relâche pour arrêter" : "Maintiens pour parler")
        .accessibilityAddTraits(.isButton)
    }

    private func ringWave(scale: CGFloat, opacity: Double) -> some View {
        Circle()
            .strokeBorder(LumenColor.accent, lineWidth: LumenSize.strokeMd)
            .frame(width: buttonSize + Self.ringInset, height: buttonSize + Self.ringInset)
            .scaleEffect(scale)
            .opacity(opacity)
    }

    private func animateRings() {
        // First ring
        withAnimation(LumenAnimation.ringWave) {
            ring1Scale = Self.ringEndScale
            ring1Opacity = 0
        }
        // Second ring offset by half a cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.breathCycle / 2) {
            withAnimation(LumenAnimation.ringWave) {
                ring2Scale = Self.ringEndScale
                ring2Opacity = 0
            }
        }
    }
}

/// Outline microphone glyph used inside MicCTA (matches the SVG in `_chrome.jsx`).
private struct MicGlyph: View {
    var size: CGFloat = 42
    var color: Color

    var body: some View {
        ZStack {
            // Capsule (microphone capsule)
            RoundedRectangle(cornerRadius: size * 0.21, style: .continuous)
                .fill(color)
                .frame(width: size * 0.34, height: size * 0.55)
                .offset(y: -size * 0.10)

            // Cradle arc (open-bottom curve)
            CradleArc()
                .stroke(color, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: size * 0.72, height: size * 0.36)
                .offset(y: size * 0.16)

            // Stand line
            Rectangle()
                .fill(color)
                .frame(width: 1.6, height: size * 0.12)
                .offset(y: size * 0.40)

            // Base bar
            Rectangle()
                .fill(color)
                .frame(width: size * 0.30, height: 1.6)
                .offset(y: size * 0.48)
        }
        .frame(width: size, height: size)
    }
}

private struct CradleArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY),
            radius: rect.width / 2,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        return p
    }
}

#if DEBUG
#Preview {
    @Previewable @State var listening = false
    VStack(spacing: LumenSpacing.xl) {
        MicCTA(isListening: listening, onPressDown: { listening = true }, onPressUp: { listening = false })
        Text(listening ? "listening…" : "idle")
            .lumenFont(.caption)
            .foregroundStyle(LumenColor.textTertiary)
    }
    .padding(LumenSpacing.l)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LumenColor.bgPrimary)
}
#endif
