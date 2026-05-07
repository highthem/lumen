#if DEBUG
import SwiftUI

struct MotionCatalog: View {
    private struct Demo: Identifiable {
        let id = UUID()
        let name: String
        let animation: Animation
        let duration: Double
    }

    private let demos: [Demo] = [
        .init(name: "instant",            animation: LumenAnimation.instant,                  duration: LumenDuration.instant),
        .init(name: "quick",              animation: LumenAnimation.quick,                    duration: LumenDuration.quick),
        .init(name: "standard",           animation: LumenAnimation.standard,                 duration: LumenDuration.smooth),
        .init(name: "decelerate",         animation: LumenAnimation.decelerate,               duration: LumenDuration.smooth),
        .init(name: "decelerateLong",     animation: LumenAnimation.decelerateLong,           duration: LumenDuration.decelerateLong),
        .init(name: "accelerate",         animation: LumenAnimation.accelerate,               duration: LumenDuration.smooth),
        .init(name: "questionnaireTrans", animation: LumenAnimation.questionnaireTransition,  duration: LumenDuration.questionnaire),
        .init(name: "moodGradient",       animation: LumenAnimation.moodGradient,             duration: LumenDuration.muted),
    ]

    @State private var triggers: [UUID: Bool] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenSpacing.l) {
                Text("Tap a row to replay the animation. Looping animations (breath, alarmPulse, ringWave, arcRotate, waveform, alarmBackdrop) are demonstrated by their host components — see BreathingCircle, MicCTA, AlarmSunrise.")
                    .lumenFont(.footnoteSerif)
                    .foregroundStyle(LumenColor.textSecondary)

                ForEach(demos) { demo in
                    Button {
                        withAnimation(demo.animation) {
                            triggers[demo.id, default: false].toggle()
                        }
                    } label: {
                        HStack(spacing: LumenSpacing.m) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(demo.name)
                                    .lumenFont(.callout)
                                    .foregroundStyle(LumenColor.textPrimary)
                                Text(String(format: "%.2fs", demo.duration))
                                    .lumenFont(.caption)
                                    .foregroundStyle(LumenColor.textTertiary)
                            }
                            .frame(width: 160, alignment: .leading)

                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(LumenColor.bgTertiary)
                                    .frame(height: 6)
                                Circle()
                                    .fill(LumenColor.accent)
                                    .frame(width: 20, height: 20)
                                    .offset(x: triggers[demo.id, default: false] ? 180 : 0)
                            }
                            .frame(height: 24)
                        }
                        .padding(.vertical, LumenSpacing.xs)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(LumenSpacing.l)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Motion")
    }
}

#Preview {
    NavigationStack { MotionCatalog() }
}
#endif
