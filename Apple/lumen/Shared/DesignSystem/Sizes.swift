import CoreGraphics

enum LumenSize {
    // Indicator dots
    static let dotSm: CGFloat = 5
    static let dotMd: CGFloat = 6
    static let dotLg: CGFloat = 7

    // Icons
    static let iconXs: CGFloat = 13
    static let iconSm: CGFloat = 14
    static let iconMd: CGFloat = 18
    static let iconLg: CGFloat = 22
    static let iconXl: CGFloat = 40

    // Controls
    static let buttonSm: CGFloat = 44
    static let fab: CGFloat = 48
    static let cta: CGFloat = 52
    static let listenPlayer: CGFloat = 56

    // Containers
    static let cardForm: CGFloat = 280
    static let cardField: CGFloat = 320
    static let cardPriority: CGFloat = 340

    // Rules / inputs
    static let ruleSm: CGFloat = 60
    static let formInput: CGFloat = 84
    static let editorMin: CGFloat = 100
    static let halfMod: CGFloat = 46

    // Vertical block / spacer minimums
    static let blockMin: CGFloat = 32
    static let blockSm: CGFloat = 40
    static let blockMd: CGFloat = 60
    static let blockLg: CGFloat = 80
    static let blockReveal: CGFloat = 130

    // Component-specific sizes
    static let iconBtn: CGFloat = 36
    static let mic: CGFloat = 96
    static let micLg: CGFloat = 120
    static let breathCircle: CGFloat = 240
    static let heroIcon: CGFloat = 48
    static let energyOrbFrame: CGFloat = 240
    static let energyOrbMin: CGFloat = 80
    static let energyOrbStep: CGFloat = 30   // orbSize = min + level * step
    static let energySliderThumb: CGFloat = 28
    static let energySliderTrack: CGFloat = 4
    static let heroQuoteMax: CGFloat = 480

    // Strokes
    static let hairline: CGFloat = 1
    static let strokeMd: CGFloat = 1.5
    static let strokeLg: CGFloat = 2

    // Sheet handle
    static let handleWidth: CGFloat = 36
    static let handleHeight: CGFloat = 5

    // Splash radial blur
    static let splashRadial: CGFloat = 320
}
