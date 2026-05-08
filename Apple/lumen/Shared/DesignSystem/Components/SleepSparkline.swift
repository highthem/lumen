import SwiftUI

/// 62×28 mini sparkline used in the post-rituel Sommeil card. Renders a
/// 7-point polyline (`points` normalized 0…1, top-left origin) plus a
/// terminal endpoint dot. JSX reference: `screens-shell.jsx:517–523`.
struct SleepSparkline: View {
    let points: [Double]                  // 7 normalized values (0…1)
    var width: CGFloat = 62
    var height: CGFloat = 28
    var stroke: CGFloat = 1.5

    /// Convenience: fill in 7 evenly spaced placeholder points if the caller
    /// has nothing to plot yet. Kept in the call-site, not the type.
    init(points: [Double], width: CGFloat = 62, height: CGFloat = 28, stroke: CGFloat = 1.5) {
        self.points = points
        self.width = width
        self.height = height
        self.stroke = stroke
    }

    var body: some View {
        Canvas { ctx, size in
            guard points.count >= 2 else { return }
            let pathPoints = points.enumerated().map { (i, value) -> CGPoint in
                let x = size.width * CGFloat(i) / CGFloat(points.count - 1)
                let clamped = max(0.0, min(1.0, value))
                let y = size.height * (1.0 - CGFloat(clamped))
                return CGPoint(x: x, y: y)
            }

            var line = Path()
            line.move(to: pathPoints[0])
            for p in pathPoints.dropFirst() {
                line.addLine(to: p)
            }
            ctx.stroke(
                line,
                with: .color(LumenColor.accent),
                style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round)
            )

            // Endpoint dot
            if let last = pathPoints.last {
                let dot = Path(ellipseIn: CGRect(
                    x: last.x - 2.5, y: last.y - 2.5, width: 5, height: 5
                ))
                ctx.fill(dot, with: .color(LumenColor.accent))
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    SleepSparkline(points: [0.55, 0.75, 0.65, 0.90, 0.70, 0.85, 0.70])
        .padding(LumenSpacing.l)
        .background(LumenColor.bgPrimary)
}
#endif
