import SwiftUI

/// V5 progress strip — 4 flex-1 segments, 3pt tall, 6pt gap.
/// `current` = 0..3, segments < current are "done" (accent), == current is "cur" (textSecondary), > current is muted.
struct ProgressDots4: View {
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color(for: index))
                    .frame(height: 3)
            }
        }
    }

    private func color(for index: Int) -> Color {
        if index < current { return LumenColor.accent }
        if index == current { return LumenColor.textSecondary }
        return LumenColor.bgTertiary
    }
}

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        ForEach(0..<4, id: \.self) { i in
            ProgressDots4(current: i)
        }
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
