import SwiftUI

/// Idle 7-day streak strip — left side shows the count, right side shows the
/// 7-day dot row. Colors and typography mirror `screens-shell.jsx:265–296`.
struct StreakStrip: View {
    let history: WeekHistory

    var body: some View {
        HStack(alignment: .center, spacing: LumenSpacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("7 derniers matins")
                    .font(.system(size: 11))
                    .tracking(0.08 * 11)
                    .textCase(.uppercase)
                    .foregroundStyle(LumenColor.textTertiary)
                completionLine
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .tracking(-0.005 * 18)
                    .foregroundStyle(LumenColor.textPrimary)
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                ForEach(history.days) { day in
                    dayDot(day)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(LumenColor.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LumenColor.divider, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(history.completedCount) matins faits sur 7")
    }

    private var completionLine: Text {
        Text("\(history.completedCount)").foregroundColor(LumenColor.accent)
            + Text(" matins faits")
    }

    @ViewBuilder
    private func dayDot(_ day: WeekHistory.DayStatus) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if day.isCompleted {
                    Circle().fill(LumenColor.accent)
                } else if day.isToday {
                    Circle().stroke(LumenColor.accent, lineWidth: 1.5)
                } else {
                    Circle()
                        .strokeBorder(
                            LumenColor.textPrimary.opacity(0.25),
                            style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2.5])
                        )
                }
            }
            .frame(width: 18, height: 18)
            Text(day.dayInitial)
                .font(.system(size: 9, weight: day.isToday ? .semibold : .regular))
                .foregroundStyle(day.isToday ? LumenColor.accent : LumenColor.textTertiary)
        }
    }
}

#if DEBUG
#Preview {
    let cal = Calendar(identifier: .gregorian)
    let today = cal.startOfDay(for: Date())
    let days = (0..<7).map { i -> WeekHistory.DayStatus in
        let d = cal.date(byAdding: .day, value: -(6 - i), to: today)!
        let initials = ["M", "M", "J", "V", "S", "D", "L"]
        return WeekHistory.DayStatus(
            date: d,
            dayInitial: initials[i],
            isCompleted: [true, true, false, true, true, true, false][i],
            isToday: i == 6
        )
    }
    let preview = WeekHistory(days: days, completedCount: 5, consecutiveStreak: 3)
    return StreakStrip(history: preview)
        .padding(LumenSpacing.l)
        .background(LumenColor.bgPrimary)
}
#endif
