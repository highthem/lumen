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

    private let buttonSize: CGFloat = 96

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
            .strokeBorder(LumenColor.accent.opacity(0.45), lineWidth: 1)
    }

    private var listeningBackground: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [LumenColor.accent.opacity(0.55), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: buttonSize / 2
                )
            )
            .scaleEffect(breathing ? 1.03 : 1.0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 4).repeatForever(autoreverses: true),
                value: breathing
            )
    }

    private var transcribedBackground: some View {
        Circle()
            .strokeBorder(LumenColor.accent.opacity(0.2), lineWidth: 1)
    }

    // MARK: - Glyphs

    private var openingGlyph: some View {
        Text("\u{201C}")
            .font(.system(size: 46, weight: .regular, design: .serif))
            .italic()
            .foregroundStyle(LumenColor.accent)
    }

    private var listeningArc: some View {
        Circle()
            .trim(from: 0, to: reduceMotion ? 0.85 : arcTrim)
            .stroke(LumenColor.accent.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .rotationEffect(.degrees(reduceMotion ? 0 : arcRotation))
            .frame(width: buttonSize - 8, height: buttonSize - 8)
    }

    private var transcribedGlyph: some View {
        Text("·")
            .font(.system(size: 32, weight: .regular, design: .serif))
            .foregroundStyle(LumenColor.accent.opacity(0.5))
    }

    // MARK: - Animation control

    private func updateAnimations(for newState: MicState) {
        guard !reduceMotion else { return }
        switch newState {
        case .listening:
            breathing = true
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                arcRotation = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                arcTrim = 0.85
            }
        case .idle, .transcribed:
            breathing = false
            arcRotation = 0
            arcTrim = 0
        }
    }
}
