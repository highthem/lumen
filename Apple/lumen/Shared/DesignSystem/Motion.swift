import SwiftUI

enum LumenDuration {
    static let instant: Double = 0.10
    static let quick: Double = 0.20
    static let smooth: Double = 0.30
    static let questionnaire: Double = 0.35
    static let decelerateLong: Double = 0.40
    static let muted: Double = 0.45
    static let slow: Double = 0.50
    static let scene: Double = 0.60
    static let alarmPulse: Double = 2.00
    static let breath: Double = 4.00
    static let alarmBackdrop: Double = 8.00
}

enum LumenAnimation {
    static let standard = Animation.easeInOut(duration: LumenDuration.smooth)
    static let quick = Animation.easeInOut(duration: LumenDuration.quick)
    static let instant = Animation.easeInOut(duration: LumenDuration.instant)
    static let decelerate = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: LumenDuration.smooth)
    static let decelerateLong = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: LumenDuration.decelerateLong)
    static let accelerate = Animation.timingCurve(0.4, 0.0, 1.0, 1.0, duration: LumenDuration.smooth)
    static let breath = Animation.easeInOut(duration: LumenDuration.breath).repeatForever(autoreverses: true)
    static let alarmPulse = Animation.easeInOut(duration: LumenDuration.alarmPulse).repeatForever(autoreverses: true)
    static let alarmBackdrop = Animation.easeInOut(duration: LumenDuration.alarmBackdrop).repeatForever(autoreverses: true)
    static let questionnaireTransition = Animation.easeInOut(duration: LumenDuration.questionnaire)

    // Component-specific animations
    static let ringWave = Animation.easeOut(duration: LumenDuration.breath).repeatForever(autoreverses: false)
    static let arcRotate = Animation.linear(duration: LumenDuration.breath).repeatForever(autoreverses: false)
    static let waveform = Animation.easeInOut(duration: LumenDuration.scene).repeatForever(autoreverses: true)
    static let moodGradient = Animation.easeOut(duration: LumenDuration.muted)
}

enum LumenDelay {
    static let charStagger: Duration = .milliseconds(38)
    static let charSlow: Duration = .milliseconds(60)
    static let beat: Duration = .milliseconds(100)
    static let pulse: Duration = .milliseconds(120)
    static let breath: Duration = .milliseconds(200)
    static let pause: Duration = .milliseconds(250)
    static let pauseLong: Duration = .milliseconds(300)
    static let settle: Duration = .milliseconds(400)
    static let exhale: Duration = .milliseconds(500)
    static let scene: Duration = .milliseconds(600)
    static let reveal: Duration = .milliseconds(800)
    static let nextScene: Duration = .milliseconds(1100)
    static let oneSecond: Duration = .seconds(1)

    static let charStaggerNs: UInt64 = 38_000_000
    static let charSlowNs: UInt64 = 60_000_000
    static let beatNs: UInt64 = 100_000_000
    static let pulseNs: UInt64 = 120_000_000
    static let breathNs: UInt64 = 200_000_000
    static let pauseNs: UInt64 = 250_000_000
    static let pauseLongNs: UInt64 = 300_000_000
    static let settleNs: UInt64 = 400_000_000
    static let exhaleNs: UInt64 = 500_000_000
    static let sceneNs: UInt64 = 600_000_000
    static let revealNs: UInt64 = 800_000_000
    static let nextSceneNs: UInt64 = 1_100_000_000
}

extension View {
    /// Apply an animation that automatically degrades to nil under Reduce Motion.
    /// Designed to plug into a value-driven `.animation(_:value:)` site.
    func lumenAnimation<V: Equatable>(_ animation: Animation?, value: V, reduceMotion: Bool) -> some View {
        self.animation(reduceMotion ? nil : animation, value: value)
    }
}
