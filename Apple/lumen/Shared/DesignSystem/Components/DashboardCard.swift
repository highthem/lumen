import SwiftUI

struct DashboardCard: View {
    let eyebrow: String
    let value: String?
    let footnote: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(eyebrow)

                Text(value ?? "—")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .lineSpacing(4)
                    .foregroundStyle(LumenColor.textPrimary)

                if let footnote {
                    Text(footnote)
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
