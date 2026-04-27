import SwiftUI

enum LumenFont: Sendable {
    case display
    case title1
    case title2
    case title3
    case body
    case bodyBold
    case callout
    case footnote
    case caption

    var size: CGFloat {
        switch self {
        case .display: 48
        case .title1: 32
        case .title2: 24
        case .title3: 20
        case .body, .bodyBold: 17
        case .callout: 15
        case .footnote: 13
        case .caption: 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display: .regular
        case .title1, .title2, .bodyBold: .semibold
        case .title3: .medium
        case .body, .callout, .footnote, .caption: .regular
        }
    }

    var design: Font.Design {
        switch self {
        case .display, .title1, .title2: .serif
        default: .default
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .display: 1.10
        case .title1: 1.15
        case .title2: 1.20
        case .title3: 1.25
        case .body, .bodyBold: 1.50
        case .callout: 1.45
        case .footnote: 1.40
        case .caption: 1.30
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display: -0.015 * size
        case .title1: -0.01 * size
        case .title2: -0.005 * size
        case .footnote: 0.02 * size
        case .caption: 0.18 * size
        default: 0
        }
    }

    var lineSpacing: CGFloat {
        size * (lineHeight - 1.0)
    }

    var font: Font {
        .system(size: size, weight: weight, design: design)
    }
}

extension View {
    func lumenFont(_ token: LumenFont) -> some View {
        self
            .font(token.font)
            .tracking(token.tracking)
            .lineSpacing(token.lineSpacing)
    }
}
