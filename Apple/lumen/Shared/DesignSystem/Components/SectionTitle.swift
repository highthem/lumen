import SwiftUI

struct SectionTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .lumenFont(.title1)
            .foregroundStyle(LumenColor.textPrimary)
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: LumenSpacing.l) {
        SectionTitle("Aujourd'hui")
        SectionTitle("Hier matin")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
