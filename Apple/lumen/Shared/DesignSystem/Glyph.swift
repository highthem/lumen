import SwiftUI

/// Font tokens for SF Symbol glyphs and small inline icons. Keeps `.font(.system(size:))`
/// off the call site while preserving the size/weight pairs the design uses.
enum LumenIconFont {
    static let xs = Font.system(size: 11, weight: .medium)
    static let sm = Font.system(size: 12, weight: .regular)
    static let smSemibold = Font.system(size: 12, weight: .semibold)
    static let md = Font.system(size: 13, weight: .regular)
    static let mdMedium = Font.system(size: 13, weight: .medium)
    static let lg = Font.system(size: 14, weight: .regular)
    static let xl = Font.system(size: 16, weight: .medium)
    static let xxl = Font.system(size: 17, weight: .medium)
    static let xxxl = Font.system(size: 18, weight: .regular)

    /// Monospaced fonts for code / API key inputs.
    static let monoSm = Font.system(size: 14, weight: .regular, design: .monospaced)

    // Semibold variants for navigation/affordance icons
    static let lgSemibold = Font.system(size: 14, weight: .semibold)
    static let xlSemibold = Font.system(size: 16, weight: .semibold)

    // Serif glyphs (quotation marks, dot decoration)
    static let serifLg = Font.system(size: 32, weight: .regular, design: .serif)
    static let serifXl = Font.system(size: 46, weight: .regular, design: .serif)
}

enum LumenLineSpacing {
    static let none: CGFloat = 0
    static let xs: CGFloat = 2
    static let s: CGFloat = 3
    static let m: CGFloat = 4
    static let l: CGFloat = 6
}
