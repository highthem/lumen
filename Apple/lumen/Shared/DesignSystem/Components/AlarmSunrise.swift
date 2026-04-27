import SwiftUI

struct AlarmSunrise: View {
    @State private var risen = false
    @State private var breathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, LumenColor.accent.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: geo.size.height * 0.36)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .scaleEffect(y: risen ? 1.0 : 0.05, anchor: .bottom)
            .opacity(breathing ? 1.0 : 0.85)
        }
        .onAppear {
            if reduceMotion {
                risen = true
                breathing = true
            } else {
                withAnimation(.easeOut(duration: 4)) {
                    risen = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        breathing = true
                    }
                }
            }
        }
    }
}
