import Foundation

enum LumenOpacity {
    // Semantic tokens
    static let surfaceFill: Double = 0.12
    static let glow: Double = 0.18
    static let subtle: Double = 0.20
    static let disabled: Double = 0.30
    static let muted: Double = 0.45
    static let dim: Double = 0.50
    static let ring: Double = 0.55
    static let waveform: Double = 0.75
    static let arc: Double = 0.80
    static let pressed: Double = 0.85

    // Explicit percentage tokens for one-off shades that carry no
    // independent semantic meaning. Prefer the named tokens above.
    static let p04: Double = 0.04
    static let p06: Double = 0.06
    static let p08: Double = 0.08
    static let p10: Double = 0.10
    static let p16: Double = 0.16
    static let p22: Double = 0.22
    static let p25: Double = 0.25
    static let p28: Double = 0.28
    static let p32: Double = 0.32
    static let p35: Double = 0.35
    static let p38: Double = 0.38
    static let p40: Double = 0.40
    static let p42: Double = 0.42
    static let p60: Double = 0.60
    static let p65: Double = 0.65
    static let p70: Double = 0.70
    static let p78: Double = 0.78
    static let p88: Double = 0.88
    static let p94: Double = 0.94
}
