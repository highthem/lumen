import SwiftUI

struct BreathingCircle: View {
    var size: CGFloat = 240
    var strokeColor: Color = LumenColor.textPrimary
    var glowColor: Color = LumenColor.accent

    @State private var breathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(strokeColor.opacity(0.5), lineWidth: 1)
                .frame(width: size, height: size)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
        }
        .scaleEffect(breathing ? 1.045 : 1.0)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 4).repeatForever(autoreverses: true),
            value: breathing
        )
        .onAppear {
            guard !reduceMotion else { return }
            breathing = true
        }
    }
}
