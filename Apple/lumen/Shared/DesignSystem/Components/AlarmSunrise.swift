import SwiftUI

struct AlarmSunrise: View {
    @State private var risen = false
    @State private var breathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let initialScaleY: CGFloat = 0.05
    private static let coverRatio: CGFloat = 0.36

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, LumenColor.accent.opacity(LumenOpacity.pressed)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: geo.size.height * Self.coverRatio)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .scaleEffect(y: risen ? 1.0 : Self.initialScaleY, anchor: .bottom)
            .opacity(breathing ? 1.0 : LumenOpacity.pressed)
        }
        .onAppear {
            if reduceMotion {
                risen = true
                breathing = true
            } else {
                withAnimation(LumenAnimation.alarmBackdrop) {
                    risen = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(LumenDuration.breath))
                    withAnimation(LumenAnimation.alarmBackdrop) {
                        breathing = true
                    }
                }
            }
        }
    }
}
