import SwiftUI

/// V4 sun-rising glyph: a circle outline + clipped fill where a horizon line cuts through the disc.
/// level 0 = sun almost fully below horizon, level 4 = almost fully risen.
struct SunGlyph: View {
    /// 0 = lowest (most below horizon), 4 = highest (most above)
    let level: Int
    var size: CGFloat = 36
    var color: Color = LumenColor.accent

    var body: some View {
        Canvas { context, canvasSize in
            let radius = canvasSize.width / 2
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

            // Horizon offsets from center, as fraction of radius:
            // level 0 → sun barely peeking (+0.85r from center = near bottom)
            // level 4 → nearly fully up (-0.95r from center = near top)
            let horizonOffsets: [CGFloat] = [0.85, 0.4, 0.0, -0.4, -0.95]
            let clampedLevel = max(0, min(4, level))
            let horizonY = center.y + horizonOffsets[clampedLevel] * radius

            // Circle outline
            let circlePath = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.stroke(circlePath, with: .color(color), lineWidth: 1.5)

            // Clipped fill — only the part above the horizon line
            let fillPath = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            var ctx = context
            ctx.clip(to: Path(CGRect(
                x: 0,
                y: 0,
                width: canvasSize.width,
                height: horizonY
            )))
            ctx.fill(fillPath, with: .color(color.opacity(0.85)))

            // Horizon line
            let horizonPath = Path { p in
                p.move(to: CGPoint(x: 0, y: horizonY))
                p.addLine(to: CGPoint(x: canvasSize.width, y: horizonY))
            }
            context.stroke(horizonPath, with: .color(color.opacity(0.6)), lineWidth: 1)
        }
        .frame(width: size, height: size)
    }
}
