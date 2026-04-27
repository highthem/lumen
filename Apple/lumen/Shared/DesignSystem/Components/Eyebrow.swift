import SwiftUI

struct Eyebrow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .regular))
            .tracking(11 * 0.22)
            .foregroundStyle(LumenColor.textTertiary)
    }
}
