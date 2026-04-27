import SwiftUI

struct SectionTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 30, weight: .medium, design: .serif))
            .lineSpacing(LumenFont.title1.lineSpacing)
            .foregroundStyle(LumenColor.textPrimary)
    }
}
