import SwiftUI

/// 36-pt color swatch shown in the post-rituel Humeur card. The hue maps the
/// 0…4 mood level (Q1 chromatic slider) to the JSX palette
/// `screens-shell.jsx:339` — kept verbatim, not promoted to a token enum
/// (it's the only consumer for now).
struct MoodSwatchOrb: View {
    let level: Int                       // 0…4 (clamped)
    var diameter: CGFloat = 36

    private static let palette: [UInt32] = [
        0x3B5066,  // 0 — deep cool
        0x5A6478,  // 1 — blue-grey
        0xA09A8C,  // 2 — muted tan
        0xD4B68C,  // 3 — warm tan
        0xF0CFA0   // 4 — golden
    ]

    private var swatch: Color {
        let clamped = max(0, min(Self.palette.count - 1, level))
        return Color(lumenHex: Self.palette[clamped])
    }

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [swatch, swatch.opacity(0.93)],
                    center: UnitPoint(x: 0.30, y: 0.30),
                    startRadius: 0,
                    endRadius: diameter * 0.8
                )
            )
            .frame(width: diameter, height: diameter)
            .shadow(color: swatch.opacity(0.33), radius: 6, y: 2)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: LumenSpacing.m) {
        ForEach(0..<5, id: \.self) { MoodSwatchOrb(level: $0) }
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
