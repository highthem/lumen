import SwiftUI

enum LumenColor {
    static let bgPrimary = Color("bgPrimary", bundle: .main)
    static let bgSecondary = Color("bgSecondary", bundle: .main)
    static let bgTertiary = Color("bgTertiary", bundle: .main)

    static let textPrimary = Color("textPrimary", bundle: .main)
    static let textSecondary = Color("textSecondary", bundle: .main)
    static let textTertiary = Color("textTertiary", bundle: .main)

    static let accent = Color("accent", bundle: .main)
    static let accentMuted = Color("accentMuted", bundle: .main)

    static let success = Color("success", bundle: .main)
    static let warning = Color("warning", bundle: .main)
    static let error = Color("errorColor", bundle: .main)

    static let divider = Color("divider", bundle: .main)

    enum Splash {
        static let earth = Color("splashEarth", bundle: .main)
        static let dawnTop = Color("splashDawnTop", bundle: .main)
        static let dawnBottom = Color("splashDawnBottom", bundle: .main)
    }

    /// Q1 chromatic-slider gradient stops. Two scales (dark/light), 5 levels.
    /// Mirrors `screens-flow.jsx` bgDark/bgLite tables — keep in sync if design updates.
    enum MoodGradient {
        private static let dark: [[Color]] = [
            [Color(lumenHex: 0x1A1714), Color(lumenHex: 0x0F0D0B)],
            [Color(lumenHex: 0x221C16), Color(lumenHex: 0x0F0D0B)],
            [Color(lumenHex: 0x3B2E22), Color(lumenHex: 0x14110E)],
            [Color(lumenHex: 0x6B4D33), Color(lumenHex: 0x1A1410)],
            [Color(lumenHex: 0xE8C39E), Color(lumenHex: 0x6B4D33), Color(lumenHex: 0x1F1812)]
        ]
        private static let light: [[Color]] = [
            [Color(lumenHex: 0xE5DDC9), Color(lumenHex: 0xF2ECDE)],
            [Color(lumenHex: 0xEBDFC8), Color(lumenHex: 0xFAF6EF)],
            [Color(lumenHex: 0xE8D5B5), Color(lumenHex: 0xFAF6EF)],
            [Color(lumenHex: 0xD9B98D), Color(lumenHex: 0xFAF6EF)],
            [Color(lumenHex: 0xC9A882), Color(lumenHex: 0xE8D5B5), Color(lumenHex: 0xFAF6EF)]
        ]

        static func stops(for level: Int, isDark: Bool) -> [Color] {
            let palette = isDark ? dark : light
            return palette[max(0, min(palette.count - 1, level))]
        }
    }

    /// Alarm-ringing sunrise gradient palette.
    enum Sunrise {
        static let base = Color(lumenHex: 0x3D2418)
        static let sun  = Color(lumenHex: 0xE8A050)
        static let halo = Color(lumenHex: 0xF5DCA8)
    }

    /// Q2 energy-orb radial-gradient stops (core + edge). Accent is the
    /// outer-most stop — defined elsewhere — these are the inner shadows.
    enum OrbCore {
        static let mid  = Color(lumenHex: 0x7A5934)
        static let deep = Color(lumenHex: 0x3A2A18)
    }
}

extension Color {
    /// Hex literal initializer (0xRRGGBB). Internal so component-specific
    /// palettes inside DesignSystem can express stops compactly without
    /// each one re-declaring the conversion.
    init(lumenHex: UInt32, alpha: Double = 1.0) {
        let r = Double((lumenHex >> 16) & 0xFF) / 255.0
        let g = Double((lumenHex >> 8) & 0xFF) / 255.0
        let b = Double(lumenHex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
