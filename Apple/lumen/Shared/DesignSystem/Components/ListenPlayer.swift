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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                content
                progressBar
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LumenColor.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(LumenColor.accent.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isPlaying ? "Pause la synthèse" : "Écouter ta synthèse")
        .accessibilityValue(isPlaying ? (elapsedLabel ?? "") : durationLabel)
    }

    // MARK: - Content

    private var content: some View {
        HStack(spacing: 12) {
            glyphDisc

            Group {
                if isPlaying, let elapsed = elapsedLabel {
                    HStack(spacing: 6) {
                        Text(elapsed)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(LumenColor.textPrimary)
                        Text("/ \(durationLabel)")
                            .font(.system(size: 13))
                            .foregroundStyle(LumenColor.textTertiary)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text("Écouter ta synthèse")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(LumenColor.textPrimary)
                        Text("· \(durationLabel)")
                            .font(.system(size: 13))
                            .foregroundStyle(LumenColor.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isPlaying {
                MiniWave()
                    .frame(width: 24, height: 16)
                    .foregroundStyle(LumenColor.accent.opacity(0.75))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var glyphDisc: some View {
        ZStack {
            Circle()
                .fill(LumenColor.accent)
                .frame(width: 36, height: 36)

            if isPlaying {
                HStack(spacing: 3) {
                    Capsule().frame(width: 3, height: 12)
                    Capsule().frame(width: 3, height: 12)
                }
                .foregroundStyle(LumenColor.bgPrimary)
            } else {
                // Right-pointing triangle
                PlayTriangle()
                    .fill(LumenColor.bgPrimary)
                    .frame(width: 11, height: 13)
                    .offset(x: 1)
            }
        }
    }

    // MARK: - Progress

    private var progressBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(LumenColor.accent)
                    .frame(width: geo.size.width * CGFloat(max(0, min(1, progress))))
                Spacer(minLength: 0)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: progress)
        }
        .frame(height: 2)
        .clipShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
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

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 3)
                    .frame(height: barHeight(index: i))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }

    private func barHeight(index: Int) -> CGFloat {
        let base: [CGFloat] = [10, 14, 8, 12]
        let amplitude: CGFloat = reduceMotion ? 0 : 4
        let offsetByPhase = sin((phase + Double(index) * 0.25) * .pi * 2) * Double(amplitude)
        return base[index] + CGFloat(offsetByPhase)
    }
}
