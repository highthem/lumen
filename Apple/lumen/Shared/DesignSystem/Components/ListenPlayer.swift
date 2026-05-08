import SwiftUI

/// Premium full-width audio player pill (V8 signature).
/// 56pt height, accent disc with play/pause glyph, label centre,
/// optional mini-wave when playing, accent progress bar pinned to bottom.
struct ListenPlayer: View {
    let isPlaying: Bool
    /// 0.0 ... 1.0, drives the bottom progress bar.
    let progress: Double
    /// Total duration label, e.g. "38 s".
    let durationLabel: String
    /// When playing, optional elapsed label, e.g. "1:12".
    let elapsedLabel: String?
    let onTap: () -> Void
    var accessibilityID: String = "synthesis-listen-button"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let glyphDiscSize: CGFloat = 36
    private static let pauseBarWidth: CGFloat = 3
    private static let pauseBarHeight: CGFloat = 12
    private static let triangleWidth: CGFloat = 11
    private static let triangleHeight: CGFloat = 13
    private static let waveBoxWidth: CGFloat = 24
    private static let waveBoxHeight: CGFloat = 16

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .leading) {
                progressBar
                content
            }
            .frame(maxWidth: .infinity)
            .frame(height: LumenSize.listenPlayer)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                    .stroke(LumenColor.accent.opacity(LumenOpacity.p35), lineWidth: LumenSize.hairline)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityID)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isPlaying ? "Pause la synthèse" : "Écouter ta synthèse")
        .accessibilityValue(isPlaying ? (elapsedLabel ?? "") : durationLabel)
    }

    // MARK: - Content

    private var content: some View {
        HStack(spacing: LumenSpacing.sm2) {
            glyphDisc

            Group {
                if isPlaying, let elapsed = elapsedLabel {
                    HStack(spacing: LumenSpacing.xs2) {
                        Text(elapsed)
                            .lumenFont(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(LumenColor.textPrimary)
                        Text("/ \(durationLabel)")
                            .lumenFont(.footnote)
                            .foregroundStyle(LumenColor.textTertiary)
                    }
                } else {
                    HStack(spacing: LumenSpacing.xs2) {
                        Text("Écouter ta synthèse")
                            .lumenFont(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(LumenColor.textPrimary)
                        Text("· \(durationLabel)")
                            .lumenFont(.footnote)
                            .foregroundStyle(LumenColor.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isPlaying {
                MiniWave()
                    .frame(width: Self.waveBoxWidth, height: Self.waveBoxHeight)
                    .foregroundStyle(LumenColor.accent.opacity(LumenOpacity.waveform))
            }
        }
        .padding(.horizontal, LumenSpacing.sm)
        .padding(.vertical, LumenSpacing.s)
    }

    private var glyphDisc: some View {
        ZStack {
            Circle()
                .fill(LumenColor.accent)
                .frame(width: Self.glyphDiscSize, height: Self.glyphDiscSize)

            if isPlaying {
                HStack(spacing: LumenSpacing.xs - LumenSpacing.xxs / 2) {
                    Capsule().frame(width: Self.pauseBarWidth, height: Self.pauseBarHeight)
                    Capsule().frame(width: Self.pauseBarWidth, height: Self.pauseBarHeight)
                }
                .foregroundStyle(LumenColor.bgPrimary)
            } else {
                // Right-pointing triangle
                PlayTriangle()
                    .fill(LumenColor.bgPrimary)
                    .frame(width: Self.triangleWidth, height: Self.triangleHeight)
                    .offset(x: 1)
            }
        }
    }

    // MARK: - Progress

    private var progressBar: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(LumenColor.accent.opacity(LumenOpacity.surfaceFill))
                .frame(width: geo.size.width * CGFloat(max(0, min(1, progress))))
                .animation(reduceMotion ? nil : LumenAnimation.standard, value: progress)
        }
        .allowsHitTesting(false)
        .accessibilityIdentifier("synthesis-progress-bar")
    }
}

// MARK: - Helpers

private struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct MiniWave: View {
    @State private var phase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let barWidth: CGFloat = 3
    private static let barSpacing: CGFloat = 3
    private static let barAmplitude: CGFloat = 4
    private static let barBaseHeights: [CGFloat] = [10, 14, 8, 12]

    var body: some View {
        HStack(alignment: .center, spacing: Self.barSpacing) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: Self.barWidth)
                    .frame(height: barHeight(index: i))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(LumenAnimation.waveform) {
                phase = 1
            }
        }
    }

    private func barHeight(index: Int) -> CGFloat {
        let amplitude: CGFloat = reduceMotion ? 0 : Self.barAmplitude
        let offsetByPhase = sin((phase + Double(index) * 0.25) * .pi * 2) * Double(amplitude)
        return Self.barBaseHeights[index] + CGFloat(offsetByPhase)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var playing = false
    @Previewable @State var progress: Double = 0.4
    VStack(spacing: LumenSpacing.l) {
        ListenPlayer(
            isPlaying: playing,
            progress: progress,
            durationLabel: "38 s",
            elapsedLabel: "0:14"
        ) {
            playing.toggle()
        }
        Slider(value: $progress, in: 0...1)
            .tint(LumenColor.accent)
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
