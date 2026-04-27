import SwiftUI

/// V5 mic-cta: 120pt round button with explicit microphone glyph.
/// Hold-to-talk: invokes `onPressDown` when finger lands, `onPressUp` on release.
struct MicCTA: View {
    let isListening: Bool
    let onPressDown: () -> Void
    let onPressUp: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false
    @State private var breath: Bool = false

    private let breathCycle: TimeInterval = 4.0

    var body: some View {
        ZStack {
            // Outer breathing rings (only while listening)
            if isListening && !reduceMotion {
                Circle()
                    .strokeBorder(LumenColor.accent, lineWidth: 1.5)
                    .frame(width: 140, height: 140)
                    .scaleEffect(breath ? 1.45 : 0.95)
                    .opacity(breath ? 0 : 0.55)
                    .animation(
                        .easeOut(duration: breathCycle).repeatForever(autoreverses: false),
                        value: breath
                    )
                Circle()
                    .strokeBorder(LumenColor.accent, lineWidth: 1.5)
                    .frame(width: 140, height: 140)
                    .scaleEffect(breath ? 1.45 : 0.95)
                    .opacity(breath ? 0 : 0.55)
                    .animation(
                        .easeOut(duration: breathCycle).repeatForever(autoreverses: false).delay(breathCycle / 2),
                        value: breath
                    )
            }

            // Main button
            ZStack {
                Circle()
                    .fill(isListening ? LumenColor.accent : LumenColor.accent.opacity(0.12))
                Circle()
                    .strokeBorder(isListening ? Color.clear : LumenColor.accent, lineWidth: 1.5)

                MicGlyph(filled: isListening)
                    .foregroundStyle(isListening ? LumenColor.bgPrimary : LumenColor.accent)
                    .frame(width: 42, height: 42)
            }
            .frame(width: 120, height: 120)
            .scaleEffect(isListening && !reduceMotion ? (breath ? 1.03 : 1.0) : 1.0)
            .animation(
                .easeInOut(duration: breathCycle).repeatForever(autoreverses: true),
                value: breath
            )
        }
        .frame(width: 160, height: 160)
        .contentShape(Circle())
        .onChange(of: isListening) { _, listening in
            if listening { breath = true } else { breath = false }
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
        .accessibilityLabel(isListening ? "Relâche pour arrêter" : "Maintiens pour parler")
        .accessibilityAddTraits(.isButton)
    }
}

/// Mic glyph (V5): rounded-rect capsule body + downward arc base + stand + foot.
/// 24×24 viewBox, scaled to fit the parent frame.
struct MicGlyph: View {
    let filled: Bool

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 24.0
            let stroke = GraphicsContext.Shading.color(.primary)
            let lineWidth: CGFloat = 1.6 * s

            // Capsule body — rounded rect 9..15 × 3..14, corner radius 3
            let bodyRect = CGRect(x: 9 * s, y: 3 * s, width: 6 * s, height: 11 * s)
            let bodyPath = Path(roundedRect: bodyRect, cornerRadius: 3 * s)
            if filled {
                ctx.fill(bodyPath, with: stroke)
            } else {
                ctx.stroke(bodyPath, with: stroke, lineWidth: lineWidth)
            }

            // Downward arc — semicircle from (5.5, 11) to (18.5, 11), bulging downward
            var arc = Path()
            arc.move(to: CGPoint(x: 5.5 * s, y: 11 * s))
            arc.addArc(
                center: CGPoint(x: 12 * s, y: 11 * s),
                radius: 6.5 * s,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: true
            )
            ctx.stroke(arc, with: stroke, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Stand
            var stand = Path()
            stand.move(to: CGPoint(x: 12 * s, y: 17.5 * s))
            stand.addLine(to: CGPoint(x: 12 * s, y: 21 * s))
            ctx.stroke(stand, with: stroke, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Foot
            var foot = Path()
            foot.move(to: CGPoint(x: 8.5 * s, y: 21 * s))
            foot.addLine(to: CGPoint(x: 15.5 * s, y: 21 * s))
            ctx.stroke(foot, with: stroke, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
}
