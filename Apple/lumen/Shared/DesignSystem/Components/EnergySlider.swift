import SwiftUI

/// Q2 horizontal slider — 5 discrete tick positions (0…4) with a single
/// thumb. Custom-drawn because stock `Slider` cannot render the
/// ticks-with-the-current-tick-hidden behavior, the accent-tinted
/// filled track, or the soft-haptic snap behavior.
struct EnergySlider: View {
    @Binding var level: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lastHapticLevel: Int = -1

    private static let stepCount = 5

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let progress = CGFloat(level) / CGFloat(Self.stepCount - 1)
                let thumbX = trackWidth * progress
                let centerY = geo.size.height / 2

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LumenColor.textPrimary.opacity(0.10))
                        .frame(height: LumenSize.energySliderTrack)

                    Capsule()
                        .fill(LumenColor.accent)
                        .frame(width: max(0, thumbX), height: LumenSize.energySliderTrack)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: level)

                    ForEach(0..<Self.stepCount, id: \.self) { i in
                        let x = trackWidth * CGFloat(i) / CGFloat(Self.stepCount - 1)
                        Rectangle()
                            .fill(LumenColor.textPrimary)
                            .opacity(i <= level ? 0.5 : 0.18)
                            .frame(width: 1, height: i == level ? 0 : 8)
                            .position(x: x, y: centerY)
                    }

                    Circle()
                        .fill(LumenColor.accent)
                        .frame(width: LumenSize.energySliderThumb, height: LumenSize.energySliderThumb)
                        .overlay(
                            Circle().stroke(LumenColor.bgPrimary.opacity(0.6), lineWidth: 4)
                        )
                        .shadow(color: LumenColor.accent.opacity(0.35), radius: 14, x: 0, y: 4)
                        .position(x: thumbX, y: centerY)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: level)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateLevel(from: value.location.x, in: trackWidth)
                        }
                )
            }
            .frame(height: 44)

            HStack {
                Text("À plat")
                    .lumenFont(.caption)
                    .textCase(.uppercase)
                    .opacity(level == 0 ? 1 : 0.5)
                Spacer()
                Text("Au top")
                    .lumenFont(.caption)
                    .textCase(.uppercase)
                    .opacity(level == 4 ? 1 : 0.5)
            }
            .foregroundStyle(LumenColor.textPrimary.opacity(0.55))
        }
        .accessibilityElement()
        .accessibilityLabel("Niveau d'énergie")
        .accessibilityValue("Niveau \(level + 1) sur 5")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if level < 4 { level += 1; LumenHaptic.moodSelect() }
            case .decrement: if level > 0 { level -= 1; LumenHaptic.moodSelect() }
            @unknown default: break
            }
        }
    }

    private func updateLevel(from x: CGFloat, in width: CGFloat) {
        guard width > 0 else { return }
        let clampedX = max(0, min(width, x))
        let raw = clampedX / width * CGFloat(Self.stepCount - 1)
        let proposed = Int(raw.rounded())
        let clamped = max(0, min(Self.stepCount - 1, proposed))
        if clamped != level {
            level = clamped
            if clamped != lastHapticLevel {
                lastHapticLevel = clamped
                LumenHaptic.moodSelect()
            }
        }
    }
}

#if DEBUG
#Preview("Levels 0…4") {
    VStack(spacing: 32) {
        ForEach(0..<5, id: \.self) { lvl in
            VStack(alignment: .leading, spacing: 6) {
                Text("level \(lvl)")
                    .lumenFont(.caption)
                    .foregroundStyle(LumenColor.textSecondary)
                EnergySlider(level: .constant(lvl))
            }
        }
    }
    .padding()
    .background(LumenColor.bgPrimary)
}

#Preview("Interactive") {
    @Previewable @State var lvl = 2
    return VStack(spacing: 24) {
        Text("Level: \(lvl)")
            .lumenFont(.body)
            .foregroundStyle(LumenColor.textPrimary)
        EnergySlider(level: $lvl)
    }
    .padding()
    .background(LumenColor.bgPrimary)
}
#endif
