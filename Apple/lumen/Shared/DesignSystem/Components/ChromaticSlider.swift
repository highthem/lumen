import SwiftUI
import UIKit

/// Full-screen vertical chromatic slider for Q1 Mood (V8 — Direction A).
/// The whole screen is the control: drag up = higher level (rayonnant),
/// drag down = lower (enfoui). Background gradient evolves with level,
/// haptic fires at each level boundary. Uses 5 discrete steps under
/// a continuous gesture.
struct ChromaticSlider<Overlay: View>: View {
    @Binding var level: Int
    @ViewBuilder var overlay: (Color) -> Overlay
    var onLevelChanged: ((Int) -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragStartLevel: Int?
    @State private var lastHapticLevel: Int = -1

    var body: some View {
        let isDark = colorScheme == .dark
        let ink: Color = isDark
            ? (level >= 4 ? ChromaticSliderTokens.brightInk : ChromaticSliderTokens.warmInk)
            : ChromaticSliderTokens.brightInk

        ZStack {
            backgroundGradient(level: level, dark: isDark)
                .ignoresSafeArea()
                .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: level)

            overlay(ink)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    if dragStartLevel == nil { dragStartLevel = level }
                    let start = dragStartLevel ?? level
                    // Negative translation.height = drag up = level up.
                    // ~70pt per step keeps the gesture deliberate but reachable.
                    let delta = -value.translation.height / 70.0
                    let proposed = Int((Double(start) + delta).rounded())
                    let clamped = max(0, min(4, proposed))
                    if clamped != level {
                        level = clamped
                        if clamped != lastHapticLevel {
                            lastHapticLevel = clamped
                            LumenHaptic.moodSelect()
                        }
                        onLevelChanged?(clamped)
                    }
                }
                .onEnded { _ in
                    dragStartLevel = nil
                }
        )
        .accessibilityRepresentation {
            Slider(
                value: Binding(
                    get: { Double(level) },
                    set: { level = max(0, min(4, Int($0.rounded()))); onLevelChanged?(level) }
                ),
                in: 0...4,
                step: 1
            )
        }
    }

    // MARK: - Gradient definitions

    /// Mirrors the bgDark/bgLite arrays in screens-flow.jsx (5 levels).
    @ViewBuilder
    private func backgroundGradient(level: Int, dark: Bool) -> some View {
        let stops = LumenColor.MoodGradient.stops(for: level, isDark: dark)
        let centerY: CGFloat = [1.10, 1.05, 1.00, 0.95, 0.90][level]
        RadialGradient(
            colors: stops,
            center: UnitPoint(x: 0.5, y: centerY),
            startRadius: 0,
            endRadius: UIScreen.main.bounds.height * 1.2
        )
    }
}

private enum ChromaticSliderTokens {
    /// Foreground ink colors. These are not background palettes — they
    /// drive text contrast over the chromatic background and depend on
    /// the slider's internal luminance heuristic, so they live with the
    /// component rather than in `LumenColor.MoodGradient`.
    static let warmInk = Color(lumenHex: 0xF5EFE6)
    static let brightInk = Color(lumenHex: 0x1F1A14)
}

#if DEBUG
#Preview {
    @Previewable @State var level = 2
    ChromaticSlider(level: $level) { ink in
        VStack(spacing: LumenSpacing.s) {
            Text("level \(level)")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(ink)
            Text("drag up or down")
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(ink.opacity(0.7))
        }
    }
}
#endif
