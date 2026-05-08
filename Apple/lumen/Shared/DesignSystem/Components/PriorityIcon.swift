import SwiftUI

/// V5 priority-card icons: 22×22 line glyphs (drawn from the V5 design SVG paths).
struct PriorityIcon: View {
    let category: PriorityCategory
    var size: CGFloat = 22

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = canvasSize.width / 24.0
            let strokeWidth: CGFloat = 1.6
            let stroke = GraphicsContext.Shading.color(.primary)

            switch category {
            case .energy:
                let centerR = 4.0 * s
                let center = CGPoint(x: 12 * s, y: 12 * s)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - centerR, y: center.y - centerR, width: centerR * 2, height: centerR * 2)),
                    with: stroke
                )
                let rays: [(CGPoint, CGPoint)] = [
                    (CGPoint(x: 12 * s, y: 3 * s),  CGPoint(x: 12 * s, y: 6 * s)),
                    (CGPoint(x: 12 * s, y: 18 * s), CGPoint(x: 12 * s, y: 21 * s)),
                    (CGPoint(x: 3 * s, y: 12 * s),  CGPoint(x: 6 * s, y: 12 * s)),
                    (CGPoint(x: 18 * s, y: 12 * s), CGPoint(x: 21 * s, y: 12 * s)),
                    (CGPoint(x: 5.5 * s, y: 5.5 * s),   CGPoint(x: 7.6 * s, y: 7.6 * s)),
                    (CGPoint(x: 16.4 * s, y: 16.4 * s), CGPoint(x: 18.5 * s, y: 18.5 * s)),
                    (CGPoint(x: 5.5 * s, y: 18.5 * s),  CGPoint(x: 7.6 * s, y: 16.4 * s)),
                    (CGPoint(x: 16.4 * s, y: 7.6 * s),  CGPoint(x: 18.5 * s, y: 5.5 * s)),
                ]
                for (a, b) in rays {
                    var p = Path(); p.move(to: a); p.addLine(to: b)
                    ctx.stroke(p, with: stroke, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                }

            case .body:
                // Heart silhouette filled at low opacity, with subtle outline
                var heart = Path()
                heart.move(to: CGPoint(x: 12 * s, y: 21 * s))
                heart.addCurve(
                    to: CGPoint(x: 5 * s, y: 10.5 * s),
                    control1: CGPoint(x: 12 * s, y: 21 * s),
                    control2: CGPoint(x: 5 * s, y: 16.5 * s)
                )
                heart.addCurve(
                    to: CGPoint(x: 12 * s, y: 6.5 * s),
                    control1: CGPoint(x: 5 * s, y: 7 * s),
                    control2: CGPoint(x: 8.5 * s, y: 5 * s)
                )
                heart.addCurve(
                    to: CGPoint(x: 19 * s, y: 10.5 * s),
                    control1: CGPoint(x: 15.5 * s, y: 5 * s),
                    control2: CGPoint(x: 19 * s, y: 7 * s)
                )
                heart.addCurve(
                    to: CGPoint(x: 12 * s, y: 21 * s),
                    control1: CGPoint(x: 19 * s, y: 16.5 * s),
                    control2: CGPoint(x: 12 * s, y: 21 * s)
                )
                ctx.fill(heart, with: GraphicsContext.Shading.color(.primary.opacity(0.18)))
                ctx.stroke(heart, with: stroke, style: StrokeStyle(lineWidth: strokeWidth, lineJoin: .round))

            case .relations:
                // 4-point star (sparkle)
                var star = Path()
                star.move(to: CGPoint(x: 12 * s, y: 2 * s))
                star.addLine(to: CGPoint(x: 13.6 * s, y: 8.4 * s))
                star.addLine(to: CGPoint(x: 20 * s, y: 10 * s))
                star.addLine(to: CGPoint(x: 13.6 * s, y: 11.6 * s))
                star.addLine(to: CGPoint(x: 12 * s, y: 18 * s))
                star.addLine(to: CGPoint(x: 10.4 * s, y: 11.6 * s))
                star.addLine(to: CGPoint(x: 4 * s, y: 10 * s))
                star.addLine(to: CGPoint(x: 10.4 * s, y: 8.4 * s))
                star.closeSubpath()
                ctx.fill(star, with: stroke)

            case .work:
                let briefcase = Path(roundedRect: CGRect(x: 3 * s, y: 6 * s, width: 18 * s, height: 13 * s), cornerRadius: 2 * s)
                ctx.stroke(briefcase, with: stroke, lineWidth: strokeWidth)
                var handle = Path()
                handle.move(to: CGPoint(x: 9 * s, y: 6 * s))
                handle.addLine(to: CGPoint(x: 9 * s, y: 4.5 * s))
                handle.addCurve(
                    to: CGPoint(x: 10.5 * s, y: 3 * s),
                    control1: CGPoint(x: 9 * s, y: 3.7 * s),
                    control2: CGPoint(x: 9.7 * s, y: 3 * s)
                )
                handle.addLine(to: CGPoint(x: 13.5 * s, y: 3 * s))
                handle.addCurve(
                    to: CGPoint(x: 15 * s, y: 4.5 * s),
                    control1: CGPoint(x: 14.3 * s, y: 3 * s),
                    control2: CGPoint(x: 15 * s, y: 3.7 * s)
                )
                handle.addLine(to: CGPoint(x: 15 * s, y: 6 * s))
                ctx.stroke(handle, with: stroke, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            case .gratitude:
                // Curve + small filled circle above
                var curve = Path()
                curve.move(to: CGPoint(x: 7 * s, y: 11 * s))
                curve.addCurve(
                    to: CGPoint(x: 12 * s, y: 18 * s),
                    control1: CGPoint(x: 7 * s, y: 13.5 * s),
                    control2: CGPoint(x: 9 * s, y: 16 * s)
                )
                curve.addCurve(
                    to: CGPoint(x: 17 * s, y: 11 * s),
                    control1: CGPoint(x: 15 * s, y: 16 * s),
                    control2: CGPoint(x: 17 * s, y: 13.5 * s)
                )
                ctx.stroke(curve, with: stroke, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                let dotR = 1.5 * s
                ctx.fill(
                    Path(ellipseIn: CGRect(x: 12 * s - dotR, y: 9 * s - dotR, width: dotR * 2, height: dotR * 2)),
                    with: stroke
                )
            }
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: LumenSpacing.l) {
        ForEach(PriorityCategory.allCases, id: \.self) { c in
            VStack(spacing: 4) {
                PriorityIcon(category: c, size: 28)
                    .foregroundStyle(LumenColor.accent)
                Text(c.rawValue).lumenFont(.caption).foregroundStyle(LumenColor.textTertiary)
            }
        }
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
