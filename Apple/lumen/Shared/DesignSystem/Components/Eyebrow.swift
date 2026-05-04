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
