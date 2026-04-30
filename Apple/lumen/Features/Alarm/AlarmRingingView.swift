import SwiftUI
import UIKit

struct AlarmRingingView: View {
    let alarmId: UUID
    let alarmRepository: any AlarmRepository
    let audioPlayer: any AudioPlaying
    var onSnooze: () -> Void = {}
    var onSilence: () -> Void = {}

    @State private var loadedAlarm: Alarm?
    @State private var copyVariant: Int = 1

    private static let copyVariants: [String] = [
        "Le matin a commencé sans toi.",
        "Bonjour.",
        "L'aube t'a attendue.",
    ]

    private static func frenchDate(now: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: now)
    }

    private static func timeString(now: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: now)
    }

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            AlarmSunrise()

            TimelineView(.periodic(from: .now, by: 30)) { context in
                content(now: context.date)
            }
        }
        .task(id: alarmId) {
            let alarm = try? await alarmRepository.fetch(id: alarmId)
            loadedAlarm = alarm
            copyVariant = Int.random(in: 0..<Self.copyVariants.count)
            // Best-effort alarm audio: even if the system notification sound is
            // suppressed (Focus, silent switch, lock-screen routing edge cases),
            // play the sound from inside the app while the ringing UI is up.
            try? await audioPlayer.configureSession()
            try? await audioPlayer.play(soundId: alarm?.soundId ?? "lumen_dawn", fadeIn: true)
        }
        .onDisappear {
            Task { await audioPlayer.stop() }
        }
    }

    private func content(now: Date) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                Text(Self.frenchDate(now: now))
                    .lumenFont(.caption)
                    .foregroundStyle(LumenColor.textTertiary)
                    .textCase(.uppercase)

                Text(Self.timeString(now: now))
                    .font(.system(size: 96, weight: .regular, design: .serif))
                    .tracking(-2.88)
                    .foregroundStyle(LumenColor.textPrimary)

                Rectangle()
                    .fill(LumenColor.textPrimary.opacity(0.65))
                    .frame(width: 60, height: 1)
                    .padding(.top, 4)

                Text(Self.copyVariants[copyVariant])
                    .font(.system(size: 18, design: .serif))
                    .italic()
                    .foregroundStyle(LumenColor.textPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                    .padding(.top, 6)
            }
            .padding(.top, 36)
            .frame(maxWidth: .infinity)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onSnooze()
                } label: {
                    Text("Snooze 5 min")
                        .font(.system(size: 17, weight: .medium))
                        .tracking(-0.085)
                        .foregroundStyle(LumenColor.accent)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                        .stroke(LumenColor.accent, lineWidth: 1.5)
                )
                .buttonStyle(.plain)

                PrimaryCTA("Silence") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSilence()
                }
            }
            .padding(.horizontal, LumenSpacing.l)
            .padding(.bottom, LumenSpacing.l)
        }
    }
}
