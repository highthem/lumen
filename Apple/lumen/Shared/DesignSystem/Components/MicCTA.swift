import SwiftUI

/// V8 mic CTA: 120pt circle, real microphone glyph.
/// - idle:        1.5pt accent border, 12% accent fill, mic outline glyph (42pt)
/// - listening:   solid accent fill, 4s breathing scale, two outward concentric ring waves
/// - transcribed: thin accent border, faded mic glyph
struct MicCTA: View {
    let isListening: Bool
    let onPressDown: () -> Void
    let onPressUp: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false
    @State private var breathScale: CGFloat = 1.0
    @State private var ring1Scale: CGFloat = 0.95
    @State private var ring1Opacity: Double = 0.55
    @State private var ring2Scale: CGFloat = 0.95
    @State private var ring2Opacity: Double = 0.55

    private let buttonSize: CGFloat = 120
    private let breathCycle: TimeInterval = 4.0

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
                        .fill(LumenColor.accent.opacity(0.12))
                        .overlay(
                            Circle().strokeBorder(LumenColor.accent, lineWidth: 1.5)
                        )
                }

                MicGlyph(size: 42, color: isListening ? LumenColor.bgPrimary : LumenColor.accent)
            }
            .frame(width: buttonSize, height: buttonSize)
            .scaleEffect(isListening && !reduceMotion ? breathScale : 1.0)
            .shadow(
                color: isListening ? LumenColor.accent.opacity(0.20) : .clear,
                radius: 30, x: 0, y: 0
            )
        }
        .frame(width: buttonSize + 40, height: buttonSize + 40)
        .contentShape(Circle())
        .onChange(of: isListening) { _, listening in
            if listening && !reduceMotion {
                withAnimation(.easeInOut(duration: breathCycle).repeatForever(autoreverses: true)) {
                    breathScale = 1.03
                }
                animateRings()
            } else {
                breathScale = 1.0
                ring1Scale = 0.95; ring1Opacity = 0.55
                ring2Scale = 0.95; ring2Opacity = 0.55
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
        .accessibilityLabel(isListening ? "Relâche pour arrêter" : "Maintiens pour parler")
        .accessibilityAddTraits(.isButton)
    }

    private func ringWave(scale: CGFloat, opacity: Double) -> some View {
        Circle()
            .strokeBorder(LumenColor.accent, lineWidth: 1.5)
            .frame(width: buttonSize + 20, height: buttonSize + 20)
            .scaleEffect(scale)
            .opacity(opacity)
    }

    private func animateRings() {
        // First ring
        withAnimation(.easeOut(duration: breathCycle).repeatForever(autoreverses: false)) {
            ring1Scale = 1.45
            ring1Opacity = 0
        }
        // Second ring offset by half a cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + breathCycle / 2) {
            withAnimation(.easeOut(duration: breathCycle).repeatForever(autoreverses: false)) {
                ring2Scale = 1.45
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
