import SwiftUI

/// Lightweight flow layout — wraps children to the next row when the
/// current line runs out of horizontal space. Used by the alarm-edit
/// recurrence chips and the dashboard idle category chip row.
struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var currentWidth: CGFloat = 0

        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if currentWidth + sz.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([sz])
                currentWidth = sz.width + spacing
            } else {
                rows[rows.count - 1].append(sz)
                currentWidth += sz.width + spacing
            }
        }

        let height = rows.reduce(CGFloat(0)) { acc, row in
            let h = row.map(\.height).max() ?? 0
            return acc + h + spacing
        } - spacing

        return CGSize(width: maxWidth, height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        let maxX = bounds.maxX

        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowHeight = max(rowHeight, sz.height)
        }
    }
}
