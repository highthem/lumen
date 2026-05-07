import SwiftUI

struct WaterfallStatusList: View {
    struct Step: Identifiable {
        let id = UUID()
        let label: String
        var sublabel: String? = nil
        let status: Status
        let statusLabel: String

        enum Status {
            case live
            case standby
            case warn
        }
    }

    let steps: [Step]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(LumenColor.textPrimary.opacity(0.18))
                                .frame(width: 1)
                                .offset(y: 22)
                        }

                        Circle()
                            .fill(dotColor(for: step.status))
                            .frame(width: 11, height: 11)
                            .overlay(
                                Circle()
                                    .stroke(dotColor(for: step.status), lineWidth: 1)
                                    .opacity(step.status == .standby ? 1 : 0)
                            )
                    }
                    .frame(width: 11)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.label)
                            .lumenFont(.chipLabel)
                            .foregroundStyle(LumenColor.textPrimary)
                        if let sub = step.sublabel {
                            Text(sub)
                                .lumenFont(.footnote)
                                .foregroundStyle(LumenColor.textSecondary)
                        }
                    }

                    Spacer()

                    Text(step.statusLabel.uppercased())
                        .lumenFont(.caption)
                        .foregroundStyle(statusTextColor(for: step.status))
                }
                .frame(height: 40)
            }
        }
    }

    private func dotColor(for status: Step.Status) -> Color {
        switch status {
        case .live:    return LumenColor.success
        case .warn:    return LumenColor.warning
        case .standby: return LumenColor.textPrimary.opacity(0.32)
        }
    }

    private func statusTextColor(for status: Step.Status) -> Color {
        switch status {
        case .live:    return LumenColor.success
        case .warn:    return LumenColor.warning
        case .standby: return LumenColor.textTertiary
        }
    }
}

#if DEBUG
#Preview {
    WaterfallStatusList(steps: [
        .init(label: "Capture vocale",     status: .live,    statusLabel: "Live"),
        .init(label: "Transcription",      sublabel: "iOS Speech", status: .live, statusLabel: "OK"),
        .init(label: "Synthèse OpenAI",    status: .standby, statusLabel: "Standby"),
        .init(label: "Repli Claude",       status: .warn,    statusLabel: "Warn"),
    ])
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
