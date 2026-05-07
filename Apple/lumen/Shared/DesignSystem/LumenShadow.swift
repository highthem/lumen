import SwiftUI

enum LumenShadow: Sendable, CaseIterable {
    case subtle
    case elevated
    case liteCard
    case accentGlow(active: Bool)
    case alarmTextHalo

    static var allCases: [LumenShadow] {
        [.subtle, .elevated, .liteCard, .accentGlow(active: true), .accentGlow(active: false), .alarmTextHalo]
    }

    var color: Color {
        switch self {
        case .subtle: .black.opacity(LumenOpacity.p10)
        case .elevated: .black.opacity(LumenOpacity.p22)
        case .liteCard: .black.opacity(LumenOpacity.p06)
        case .accentGlow(let active): active ? LumenColor.accent.opacity(LumenOpacity.subtle) : .clear
        case .alarmTextHalo: LumenColor.bgPrimary.opacity(LumenOpacity.muted)
        }
    }

    var radius: CGFloat {
        switch self {
        case .subtle: 2
        case .elevated: 14
        case .liteCard: 16
        case .accentGlow: 30
        case .alarmTextHalo: 18
        }
    }

    var x: CGFloat { 0 }

    var y: CGFloat {
        switch self {
        case .subtle: 1
        case .elevated: 8
        case .liteCard: 4
        case .accentGlow, .alarmTextHalo: 0
        }
    }
}

extension View {
    func lumenShadow(_ shadow: LumenShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
