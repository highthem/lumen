import SwiftUI

struct GhostCTA: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
                .padding(.horizontal, LumenSpacing.l)
                .padding(.vertical, LumenSpacing.s)
        }
    }
}
