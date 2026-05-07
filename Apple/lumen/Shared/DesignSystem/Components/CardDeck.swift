import SwiftUI
import UIKit

/// Component-internal stack geometry for CardDeck. Pulled out of the generic
/// type because Swift forbids static stored properties on generic structs.
private enum CardDeckLayout {
    static let stackOffsetX: CGFloat = 14
    static let stackOffsetsY: [CGFloat] = [0, -14, -26, -38]
    static let stackScales: [CGFloat] = [1.0, 0.94, 0.88, 0.84]
    static let dragFadeDistance: Double = 800
    static let dragFadeMax: Double = 0.15
}

/// Swipeable card deck for Q2 Priority (V8 — Direction A).
/// 6 cards stacked, top one crisp, swipe horizontal to navigate, tap to select.
struct CardDeck<Item: Hashable, Card: View>: View {
    let items: [Item]
    @Binding var current: Int
    @Binding var selected: Item?
    var cardHeight: CGFloat = LumenSize.cardForm
    @ViewBuilder var card: (Item, Bool) -> Card

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0
    private let swipeThreshold: CGFloat = LumenSpacing.xxl2

    var body: some View {
        VStack(spacing: LumenSpacing.m) {
            HStack(alignment: .center, spacing: LumenSpacing.sm2) {
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
                .frame(height: cardHeight + LumenSpacing.xl2, alignment: .bottom)
                .gesture(
                    DragGesture(minimumDistance: LumenSpacing.s)
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
                            withAnimation(reduceMotion ? nil : LumenAnimation.standard) {
                                dragOffset = 0
                            }
                        }
                )

                navButton(systemName: "chevron.right", enabled: current < items.count - 1) {
                    advance(by: 1)
                }
            }

            HStack(spacing: LumenSpacing.s) {
                HStack(spacing: LumenSize.dotSm) {
                    ForEach(0..<items.count, id: \.self) { i in
                        Circle()
                            .fill(i == current ? LumenColor.accent : LumenColor.textPrimary.opacity(LumenOpacity.subtle))
                            .frame(width: i == current ? LumenSize.dotMd : LumenSize.dotSm,
                                   height: i == current ? LumenSize.dotMd : LumenSize.dotSm)
                    }
                }
                Text("\(current + 1) / \(items.count)")
                    .lumenFont(.caption)
                    .foregroundStyle(LumenColor.textTertiary)
                    .padding(.leading, LumenSpacing.xs2)
            }
        }
    }

    // MARK: - Navigation

    private func advance(by step: Int) {
        let next = max(0, min(items.count - 1, current + step))
        guard next != current else { return }
        // No haptic — spec forbids haptic inside questionnaire (pollutes calm).
        withAnimation(reduceMotion ? nil : LumenAnimation.standard) {
            current = next
        }
    }

    @ViewBuilder
    private func navButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(LumenIconFont.xlSemibold)
                .foregroundStyle(LumenColor.textSecondary.opacity(enabled ? LumenOpacity.pressed : LumenOpacity.disabled))
                .frame(width: LumenSize.iconBtn, height: LumenSize.iconBtn)
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
        return CGFloat(pos) * CardDeckLayout.stackOffsetX
    }

    private func offsetY(pos: Int) -> CGFloat {
        // Rear cards peek UPWARD behind the front card.
        let idx = min(abs(pos), CardDeckLayout.stackOffsetsY.count - 1)
        return CardDeckLayout.stackOffsetsY[idx]
    }

    private func scale(pos: Int) -> CGFloat {
        let idx = min(abs(pos), CardDeckLayout.stackScales.count - 1)
        return CardDeckLayout.stackScales[idx]
    }

    private func opacity(pos: Int) -> Double {
        if pos == 0 {
            // Fade slightly when dragging hard
            return 1.0 - min(CardDeckLayout.dragFadeMax, abs(Double(dragOffset)) / CardDeckLayout.dragFadeDistance)
        }
        switch abs(pos) {
        case 1: return LumenOpacity.p60 // 0.62 → snap to 0.60
        case 2: return LumenOpacity.p32
        default: return 0
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var current = 0
    @Previewable @State var selected: DashboardCategory? = nil
    CardDeck(items: DashboardCategory.allCases, current: $current, selected: $selected) { item, isSel in
        VStack(spacing: LumenSpacing.m) {
            PriorityIcon(category: item, size: 32)
                .foregroundStyle(LumenColor.accent)
            Text(item.displayName)
                .lumenFont(.title2)
                .foregroundStyle(LumenColor.textPrimary)
            if isSel {
                Text("selected")
                    .lumenFont(.caption)
                    .foregroundStyle(LumenColor.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LumenSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: LumenRadius.l)
                .fill(LumenColor.bgSecondary)
        )
        .onTapGesture { selected = item }
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
