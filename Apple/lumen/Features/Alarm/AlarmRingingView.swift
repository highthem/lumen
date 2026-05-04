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

            // Soft radial scrim behind the greeting block — keeps the
            // typography readable through the rising sunrise gradient.
            RadialGradient(
                colors: [
                    LumenColor.bgPrimary.opacity(LumenOpacity.ring),
                    LumenColor.bgPrimary.opacity(LumenOpacity.p25),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: LumenSize.iconXl,
                endRadius: LumenSize.cardForm
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()

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
            VStack(spacing: LumenSpacing.sm3) {
                Text(Self.frenchDate(now: now))
                    .lumenFont(.caption)
                    .foregroundStyle(LumenColor.textTertiary)
                    .textCase(.uppercase)

                Text(Self.timeString(now: now))
                    .lumenFont(.alarmHero)
                    .foregroundStyle(LumenColor.textPrimary)

                Rectangle()
                    .fill(LumenColor.textPrimary.opacity(LumenOpacity.p65))
                    .frame(width: LumenSize.ruleSm, height: LumenSize.hairline)
                    .padding(.top, LumenSpacing.xs)

                Text(Self.copyVariants[copyVariant])
                    .lumenFont(.title1)
                    .italic()
                    .foregroundStyle(LumenColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: LumenSize.cardField)
                    .lumenShadow(.alarmTextHalo)
                    .padding(.top, LumenSpacing.sm2)
            }
            .padding(.top, LumenSpacing.xl2)
            .frame(maxWidth: .infinity)

            Spacer()

            VStack(spacing: LumenSpacing.sm2) {
                Button {
                    onSnooze()
                } label: {
                    Text("Snooze 5 min")
                        .lumenFont(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(LumenColor.accent)
                        .frame(maxWidth: .infinity, minHeight: LumenSize.cta)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                        .stroke(LumenColor.accent, lineWidth: LumenSize.strokeMd)
                )
                .buttonStyle(.plain)

                PrimaryCTA("Silence") {
                    LumenHaptic.alarmSilence()
                    onSilence()
                }
            }
            .padding(.horizontal, LumenSpacing.l)
            .padding(.bottom, LumenSpacing.l)
        }
    }
}
