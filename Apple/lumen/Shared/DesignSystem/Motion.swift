import SwiftUI

enum LumenDuration {
    static let instant: Double = 0.10
    static let quick: Double = 0.20
    static let smooth: Double = 0.30
    static let slow: Double = 0.50
    static let breath: Double = 4.00
}

enum LumenAnimation {
    static let standard = Animation.easeInOut(duration: LumenDuration.smooth)
    static let quick = Animation.easeInOut(duration: LumenDuration.quick)
    static let decelerate = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: LumenDuration.smooth)
    static let accelerate = Animation.timingCurve(0.4, 0.0, 1.0, 1.0, duration: LumenDuration.smooth)
    static let breath = Animation.easeInOut(duration: LumenDuration.breath).repeatForever(autoreverses: true)
}

extension View {
    /// Apply an animation that automatically degrades to nil under Reduce Motion.
    /// Designed to plug into a value-driven `.animation(_:value:)` site.
    func lumenAnimation<V: Equatable>(_ animation: Animation?, value: V, reduceMotion: Bool) -> some View {
        self.animation(reduceMotion ? nil : animation, value: value)
    }
}
