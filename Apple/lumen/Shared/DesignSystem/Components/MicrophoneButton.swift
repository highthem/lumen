import SwiftUI

enum MicState: Equatable {
    case idle
    case listening
    case transcribed
}

struct MicrophoneButton: View {
    let state: MicState
    let action: () -> Void

    @State private var breathing = false
    @State private var arcRotation: Double = 0
    @State private var arcTrim: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let buttonSize: CGFloat = LumenSize.mic

    private static let arcTrimTarget: Double = 0.85
    private static let breathTargetScale: CGFloat = 1.03
    private static let arcInset: CGFloat = 8

    var body: some View {
        Button(action: action) {
            ZStack {
                switch state {
                case .idle:
                    idleBackground
                    openingGlyph
                case .listening:
                    listeningBackground
                    listeningArc
                case .transcribed:
                    transcribedBackground
                    transcribedGlyph
                }
            }
            .frame(width: buttonSize, height: buttonSize)
        }
        .buttonStyle(.plain)
        .onChange(of: state) { _, newState in
            updateAnimations(for: newState)
        }
        .onAppear {
            updateAnimations(for: state)
        }
    }

    // MARK: - Backgrounds

    private var idleBackground: some View {
        Circle()
            .strokeBorder(LumenColor.accent.opacity(LumenOpacity.muted), lineWidth: LumenSize.hairline)
    }

    private var listeningBackground: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [LumenColor.accent.opacity(LumenOpacity.ring), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: buttonSize / 2
                )
            )
            .scaleEffect(breathing ? Self.breathTargetScale : 1.0)
            .animation(reduceMotion ? nil : LumenAnimation.breath, value: breathing)
    }

    private var transcribedBackground: some View {
        Circle()
            .strokeBorder(LumenColor.accent.opacity(LumenOpacity.subtle), lineWidth: LumenSize.hairline)
    }

    // MARK: - Glyphs

    private var openingGlyph: some View {
        Text("\u{201C}")
            .font(LumenIconFont.serifXl)
            .italic()
            .foregroundStyle(LumenColor.accent)
    }

    private var listeningArc: some View {
        Circle()
            .trim(from: 0, to: reduceMotion ? Self.arcTrimTarget : arcTrim)
            .stroke(LumenColor.accent.opacity(LumenOpacity.arc), style: StrokeStyle(lineWidth: LumenSize.strokeLg, lineCap: .round))
            .rotationEffect(.degrees(reduceMotion ? 0 : arcRotation))
            .frame(width: buttonSize - Self.arcInset, height: buttonSize - Self.arcInset)
    }

    private var transcribedGlyph: some View {
        Text("·")
            .font(LumenIconFont.serifLg)
            .foregroundStyle(LumenColor.accent.opacity(LumenOpacity.dim))
    }

    // MARK: - Animation control

    private func updateAnimations(for newState: MicState) {
        guard !reduceMotion else { return }
        switch newState {
        case .listening:
            breathing = true
            withAnimation(LumenAnimation.arcRotate) {
                arcRotation = 360
            }
            withAnimation(LumenAnimation.alarmPulse) {
                arcTrim = Self.arcTrimTarget
            }
        case .idle, .transcribed:
            breathing = false
            arcRotation = 0
            arcTrim = 0
        }
    }
}
