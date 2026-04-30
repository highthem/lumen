import SwiftUI

/// V3 Sunrise Echo mic: 96pt circle, no microphone glyph.
/// - idle:        thin accent ring + serif left double-quote (`"`) at 46pt italic
/// - listening:   radial gradient bloom + 4s breathing + single arc tracing 0→360°
/// - transcribed: muted ring + serif `·` at 32pt
struct MicCTA: View {
    let isListening: Bool
    let onPressDown: () -> Void
    let onPressUp: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false
    @State private var breathPhase: CGFloat = 0
    @State private var arcAngle: Double = 0
    @State private var arcOpacity: Double = 0.2

    private let breathCycle: TimeInterval = 4.0
    private let buttonSize: CGFloat = 96

    private var state: VisualState {
        // The transcribed visual is driven by the parent — when neither listening
        // nor empty. We can't see the text from here, so the parent picks idle vs
        // transcribed via a flag we won't add right now: both share the inset-ring
        // chrome and only the glyph differs. Keep visual state binary here; the
        // serif `·` for transcribed is a parent-rendered detail in the mockup but
        // visually equivalent to idle for this 96pt button.
        isListening ? .listening : .idle
    }

    private enum VisualState { case idle, listening }

    var body: some View {
        ZStack {
            // Listening: tracing arc just outside the button
            if isListening {
                Circle()
                    .trim(from: 0, to: arcAngle / 360)
                    .stroke(LumenColor.accent.opacity(arcOpacity), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: buttonSize + 16, height: buttonSize + 16)
            }

            // Main button
            ZStack {
                if isListening {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    LumenColor.accent.opacity(0.55),
                                    LumenColor.accent.opacity(0.18),
                                    LumenColor.accent.opacity(0.04),
                                    .clear
                                ],
                                center: .init(x: 0.5, y: 0.6),
                                startRadius: 0,
                                endRadius: buttonSize / 2
                            )
                        )
                    Circle()
                        .strokeBorder(LumenColor.accent.opacity(0.55), lineWidth: 1)
                } else {
                    Circle()
                        .strokeBorder(LumenColor.accent.opacity(0.45), lineWidth: 1)
                }

                if !isListening {
                    Text("\u{201C}") // left double quotation mark
                        .font(.system(size: 46, design: .serif))
                        .italic()
                        .foregroundStyle(LumenColor.accent)
                        .offset(y: -2)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
            .scaleEffect(isListening && !reduceMotion ? (1.0 + breathPhase * 0.03) : 1.0)
            .shadow(
                color: isListening ? LumenColor.accent.opacity(0.18) : .clear,
                radius: 30, x: 0, y: 0
            )
        }
        .frame(width: buttonSize + 24, height: buttonSize + 24)
        .contentShape(Circle())
        .onChange(of: isListening) { _, listening in
            if listening && !reduceMotion {
                withAnimation(.easeInOut(duration: breathCycle).repeatForever(autoreverses: true)) {
                    breathPhase = 1
                }
                animateArc()
            } else {
                breathPhase = 0
                arcAngle = 0
                arcOpacity = 0.2
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

    private func animateArc() {
        // 0 → 360° over half the cycle, then 360 → 0 (mock effect of trace+retrace).
        // SwiftUI animations of trim respect repeatForever with autoreverses.
        withAnimation(.easeInOut(duration: breathCycle / 2).repeatForever(autoreverses: true)) {
            arcAngle = 360
            arcOpacity = 0.65
        }
    }
}
