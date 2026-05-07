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
        let stops: [Color] = dark
            ? ChromaticSliderTokens.darkStops[level]
            : ChromaticSliderTokens.lightStops[level]
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
    static let warmInk = Color(red: 0xF5/255, green: 0xEF/255, blue: 0xE6/255)
    static let brightInk = Color(red: 0x1F/255, green: 0x1A/255, blue: 0x14/255)

    static let darkStops: [[Color]] = [
        [Color(hex: 0x1A1714), Color(hex: 0x0F0D0B)],
        [Color(hex: 0x221C16), Color(hex: 0x0F0D0B)],
        [Color(hex: 0x3B2E22), Color(hex: 0x14110E)],
        [Color(hex: 0x6B4D33), Color(hex: 0x1A1410)],
        [Color(hex: 0xE8C39E), Color(hex: 0x6B4D33), Color(hex: 0x1F1812)]
    ]

    static let lightStops: [[Color]] = [
        [Color(hex: 0xE5DDC9), Color(hex: 0xF2ECDE)],
        [Color(hex: 0xEBDFC8), Color(hex: 0xFAF6EF)],
        [Color(hex: 0xE8D5B5), Color(hex: 0xFAF6EF)],
        [Color(hex: 0xD9B98D), Color(hex: 0xFAF6EF)],
        [Color(hex: 0xC9A882), Color(hex: 0xE8D5B5), Color(hex: 0xFAF6EF)]
    ]
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
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
