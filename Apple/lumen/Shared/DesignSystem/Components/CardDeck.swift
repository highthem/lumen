import SwiftUI
import UIKit

/// Swipeable card deck for Q2 Priority (V8 — Direction A).
/// 6 cards stacked, top one crisp, swipe horizontal to navigate, tap to select.
struct CardDeck<Item: Hashable, Card: View>: View {
    let items: [Item]
    @Binding var current: Int
    @Binding var selected: Item?
    var cardHeight: CGFloat = 280
    @ViewBuilder var card: (Item, Bool) -> Card

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0
    private let swipeThreshold: CGFloat = 60

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                navButton(systemName: "chevron.left", enabled: current > 0) {
                    advance(by: -1)
                }

                ZStack {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        let pos = index - current
                        if abs(pos) <= 2 {
                            card(item, item == selected)
                                .transition(.identity)
                                .offset(x: offsetX(pos: pos), y: offsetY(pos: pos))
                                .scaleEffect(scale(pos: pos))
                                .opacity(opacity(pos: pos))
                                .zIndex(Double(-abs(pos)))
                                .allowsHitTesting(pos == 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: cardHeight + 50)
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            // Only allow drag on the top card, in directions where
                            // there's actually a neighbour to swipe to.
                            let dx = value.translation.width
                            if (dx < 0 && current >= items.count - 1) ||
                               (dx > 0 && current <= 0) {
                                dragOffset = dx / 4
                            } else {
                                dragOffset = dx
                            }
                        }
                        .onEnded { value in
                            let dx = value.translation.width
                            if dx <= -swipeThreshold {
                                advance(by: 1)
                            } else if dx >= swipeThreshold {
                                advance(by: -1)
                            }
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) {
                                dragOffset = 0
                            }
                        }
                )

                navButton(systemName: "chevron.right", enabled: current < items.count - 1) {
                    advance(by: 1)
                }
            }

            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    ForEach(0..<items.count, id: \.self) { i in
                        Circle()
                            .fill(i == current ? LumenColor.accent : LumenColor.textPrimary.opacity(0.20))
                            .frame(width: i == current ? 6 : 5, height: i == current ? 6 : 5)
                    }
                }
                Text("\(current + 1) / \(items.count)")
                    .font(.system(size: 11, weight: .regular))
                    .tracking(1.4)
                    .foregroundStyle(LumenColor.textTertiary)
                    .padding(.leading, 6)
            }
        }
    }

    // MARK: - Navigation

    private func advance(by step: Int) {
        let next = max(0, min(items.count - 1, current + step))
        guard next != current else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.32)) {
            current = next
        }
    }

    @ViewBuilder
    private func navButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LumenColor.textSecondary.opacity(enabled ? 0.85 : 0.30))
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }

    // MARK: - Card transforms

    /// pos 0 = current, +1 = next behind, +2 = behind that, -1 = previous behind.
    private func offsetX(pos: Int) -> CGFloat {
        if pos == 0 { return dragOffset }
        // Stack peeks slightly to the right for "next" cards.
        return CGFloat(pos) * 14
    }

    private func offsetY(pos: Int) -> CGFloat {
        switch abs(pos) {
        case 0: 0
        case 1: 18
        case 2: 34
        default: 50
        }
    }

    private func scale(pos: Int) -> CGFloat {
        switch abs(pos) {
        case 0: 1.0
        case 1: 0.96
        case 2: 0.92
        default: 0.88
        }
    }

    private func opacity(pos: Int) -> Double {
        if pos == 0 {
            // Fade slightly when dragging hard
            return 1.0 - min(0.15, abs(Double(dragOffset)) / 800)
        }
        switch abs(pos) {
        case 1: return 0.55
        case 2: return 0.25
        default: return 0
        }
    }
}
