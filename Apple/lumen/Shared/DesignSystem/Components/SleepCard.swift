import SwiftUI

struct SleepCard: View {
    let summary: SleepSummary?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                Eyebrow("Sommeil")

                if let summary {
                    populated(summary: summary)
                } else {
                    empty
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(LumenSpacing.l)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard-card-sleep")
    }

    @ViewBuilder
    private func populated(summary: SleepSummary) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.xs) {
            Text(summary.durationLabel)
                .lumenFont(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(LumenColor.textPrimary)
            Text(summary.quality.displayName)
                .lumenFont(.footnote)
                .foregroundStyle(LumenColor.textTertiary)
        }
        sleepBar(summary: summary)
            .padding(.top, LumenSpacing.xs)
    }

    @ViewBuilder
    private var empty: some View {
        HStack(alignment: .center, spacing: LumenSpacing.s) {
            Image(systemName: "heart.fill")
                .font(.system(size: 22))
                .foregroundStyle(LumenColor.accent.opacity(LumenOpacity.p60))
            Text("Active Apple Santé\npour voir ta nuit")
                .lumenFont(.callout)
                .foregroundStyle(LumenColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func sleepBar(summary: SleepSummary) -> some View {
        let total = max(summary.totalAsleep + summary.awake, 1)
        let segments: [(opacity: Double, fraction: Double)] = [
            (1.0, summary.deep / total),
            (0.78, summary.rem / total),
            (0.5, summary.core / total),
            (0.2, summary.awake / total)
        ]
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    LumenColor.accent
                        .opacity(seg.opacity)
                        .frame(width: geo.size.width * CGFloat(seg.fraction))
                }
            }
            .frame(height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        }
        .frame(height: 6)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.m) {
        SleepCard(
            summary: SleepSummary(
                bedtime: Date().addingTimeInterval(-8 * 3600),
                wakeTime: Date(),
                totalAsleep: 7 * 3600 + 12 * 60,
                deep: 90 * 60,
                rem: 110 * 60,
                core: 4 * 3600,
                awake: 20 * 60
            ),
            onTap: {}
        )
        SleepCard(summary: nil, onTap: {})
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
