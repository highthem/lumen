import SwiftUI
import UIKit

struct AlarmRingingView: View {
    let alarm: Alarm
    var onSnooze: () -> Void = {}
    var onSilence: () -> Void = {}

    private var frenchDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: Date())
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: alarm.time)
    }

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            AlarmSunrise()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: LumenSpacing.l) {
                    Text(frenchDate)
                        .lumenFont(.callout)
                        .foregroundStyle(LumenColor.textSecondary)
                        .textCase(.uppercase)

                    Text(timeString)
                        .font(.system(size: 96, weight: .regular, design: .serif))
                        .foregroundStyle(LumenColor.textPrimary)

                    Rectangle()
                        .fill(LumenColor.accent)
                        .frame(width: 60, height: 1)

                    Text("Bonjour.")
                        .font(.system(size: 18, design: .serif))
                        .italic()
                        .foregroundStyle(LumenColor.textPrimary.opacity(0.7))
                }

                Spacer()

                VStack(spacing: LumenSpacing.m) {
                    SecondaryCTA("Snooze 5 min") {
                        onSnooze()
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.m))

                    PrimaryCTA("Silence") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSilence()
                    }
                }
                .padding(LumenSpacing.l)
            }
        }
    }
}
