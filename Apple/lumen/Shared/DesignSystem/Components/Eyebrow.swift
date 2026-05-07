import SwiftUI

struct Eyebrow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .lumenFont(.caption)
            .foregroundStyle(LumenColor.textTertiary)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        Eyebrow("Section eyebrow")
        Eyebrow("Aujourd'hui")
        Eyebrow("Énergie")
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
