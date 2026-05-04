import SwiftUI

struct BreathingCircle: View {
    var size: CGFloat = LumenSize.breathCircle
    var strokeColor: Color = LumenColor.textPrimary
    var glowColor: Color = LumenColor.accent

    @State private var breathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let breathScale: CGFloat = 1.045

    var body: some View {
        ZStack {
            Circle()
                .stroke(strokeColor.opacity(LumenOpacity.dim), lineWidth: LumenSize.hairline)
                .frame(width: size, height: size)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(LumenOpacity.glow), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
        }
        .scaleEffect(breathing ? Self.breathScale : 1.0)
        .animation(reduceMotion ? nil : LumenAnimation.breath, value: breathing)
        .onAppear {
            guard !reduceMotion else { return }
            breathing = true
        }
    }
}
