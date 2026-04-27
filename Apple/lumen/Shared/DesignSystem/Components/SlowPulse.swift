import SwiftUI

struct SlowPulse: View {
    var size: CGFloat = 160

    @State private var breathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(LumenColor.textPrimary.opacity(0.25), lineWidth: 1)
                .frame(width: size, height: size)
                .scaleEffect(breathing ? 1.08 : 1.0)

            Circle()
                .stroke(LumenColor.textPrimary.opacity(0.15), lineWidth: 1)
                .frame(width: size * 0.7, height: size * 0.7)
                .scaleEffect(breathing ? 1.08 : 1.0)
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 3.6).repeatForever(autoreverses: true),
            value: breathing
        )
        .onAppear {
            guard !reduceMotion else { return }
            breathing = true
        }
    }
}
