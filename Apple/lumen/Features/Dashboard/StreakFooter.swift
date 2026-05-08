import SwiftUI

/// Post-rituel footer strip — left: star + "Ne matin de suite" using
/// `WeekHistory.consecutiveStreak`; right: italic "prochaine alarme · …"
/// JSX reference: `screens-shell.jsx:528–539`.
struct StreakFooter: View {
    let consecutiveStreak: Int
    /// "HH:mm" of the next active alarm (already formatted by the ViewModel),
    /// or nil if none scheduled.
    let nextAlarmLabel: String?

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(LumenColor.textTertiary)
                Text(streakText)
                    .font(.system(size: 11))
                    .tracking(0.04 * 11)
                    .foregroundStyle(LumenColor.textTertiary)
            }
            Spacer()
            if let label = nextAlarmLabel {
                Text("prochaine alarme · demain \(label.replacingOccurrences(of: ":", with: " h "))")
                    .font(.system(size: 11))
                    .italic()
                    .foregroundStyle(LumenColor.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, LumenSpacing.sm2)
        .accessibilityElement(children: .combine)
    }

    private var streakText: String {
        if consecutiveStreak <= 0 { return "premier matin" }
        if consecutiveStreak == 1 { return "1er matin de suite" }
        return "\(consecutiveStreak)\u{1D49}\u{0020}matin de suite"
            .replacingOccurrences(of: "\u{1D49}", with: "ᵉ")
    }
}

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        StreakFooter(consecutiveStreak: 3, nextAlarmLabel: "06:45")
        StreakFooter(consecutiveStreak: 1, nextAlarmLabel: "07:00")
        StreakFooter(consecutiveStreak: 0, nextAlarmLabel: nil)
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
