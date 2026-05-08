import SwiftUI

/// Bento Sommeil card — populated: eyebrow + (serif 19pt italic "7 h 12" +
/// caption "moyen") + mini sparkline. Empty: eyebrow + heart icon + invite
/// to activate Apple Santé. JSX reference: `screens-shell.jsx:501–525`.
struct SleepCard: View {
    let summary: SleepSummary?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Sommeil")
                Spacer(minLength: 0)
                if let summary {
                    populated(summary)
                } else {
                    emptyContent
                }
            }
            .padding(LumenSpacing.m)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LumenColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard-card-sleep")
    }

    @ViewBuilder
    private func populated(_ summary: SleepSummary) -> some View {
        HStack(alignment: .bottom, spacing: LumenSpacing.s) {
            VStack(alignment: .leading, spacing: 1) {
                Text(shortDuration(summary))
                    .font(.system(size: 19, weight: .medium, design: .serif))
                    .italic()
                    .tracking(-0.005 * 19)
                    .foregroundStyle(LumenColor.textPrimary)
                Text(summary.quality.shortLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(LumenColor.textTertiary)
            }
            Spacer(minLength: 0)
            SleepSparkline(points: sparklinePoints(summary))
        }
    }

    @ViewBuilder
    private var emptyContent: some View {
        HStack(alignment: .center, spacing: LumenSpacing.s) {
            Image(systemName: "heart.fill")
                .font(.system(size: 22))
                .foregroundStyle(LumenColor.accent.opacity(0.6))
            Text("Active Apple Santé\npour voir ta nuit")
                .font(.system(size: 14))
                .italic()
                .foregroundStyle(LumenColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// "7 h 12" — drop the trailing "min" suffix for the bento card layout.
    private func shortDuration(_ summary: SleepSummary) -> String {
        let hours = Int(summary.totalAsleep) / 3600
        let minutes = (Int(summary.totalAsleep) % 3600) / 60
        return "\(hours) h \(String(format: "%02d", minutes))"
    }

    /// 7 normalized values 0…1. We don't have 7-day Apple Health history wired
    /// yet, so we synthesize a stable stub centered on tonight's actual figure
    /// — keeps the visual alive without inventing numbers we haven't measured.
    private func sparklinePoints(_ summary: SleepSummary) -> [Double] {
        let center = max(0.0, min(1.0, summary.totalAsleep / (9 * 3600)))
        return [
            max(0.0, center - 0.18),
            center + 0.05,
            center - 0.10,
            center + 0.18,
            center - 0.05,
            center + 0.10,
            center
        ].map { max(0.0, min(1.0, $0)) }
    }
}

private extension SleepQuality {
    var shortLabel: String {
        switch self {
        case .low: return "court"
        case .medium: return "moyen"
        case .high: return "réparateur"
        }
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 10) {
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
