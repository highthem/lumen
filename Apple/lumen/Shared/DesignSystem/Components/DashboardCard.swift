import SwiftUI

struct DashboardCard: View {
    let eyebrow: String
    let value: String?
    let footnote: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LumenSpacing.xs2) {
                Eyebrow(eyebrow)

                Text(value ?? "—")
                    .lumenFont(.title2)
                    .foregroundStyle(LumenColor.textPrimary)

                if let footnote {
                    Text(footnote)
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LumenSpacing.l)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        DashboardCard(eyebrow: "Énergie", value: "7 / 10", footnote: "Pic à 9h", action: {})
        DashboardCard(eyebrow: "Intention", value: nil, footnote: nil, action: {})
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
