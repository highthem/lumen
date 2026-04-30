import SwiftUI

/// Centred serif input with an accent underline that **hugs the text** rather
/// than the field's frame. Used by Q3 (multi-line gratitude), Q4 (single-word
/// intention) and AskLumen — anywhere the design calls for "italic serif text
/// with a thin accent rule directly underneath".
///
/// Built on `TextField(_:text:axis:)` (iOS 16+) which auto-grows vertically to
/// fit content, so the underline always sits one row below the cursor — unlike
/// `TextEditor` which has fixed minimum height and inner padding that pushes
/// the rule far from the text.
struct SerifUnderlineField: View {
    @Binding var text: String

    var placeholder: String = ""
    var fontSize: CGFloat = 22
    var weight: Font.Weight = .medium
    var italic: Bool = true
    var tracking: CGFloat = -0.33
    var lineSpacing: CGFloat = 2
    var color: Color = LumenColor.textPrimary
    var underlineColor: Color = LumenColor.accent
    var maxWidth: CGFloat = 320
    /// `nil` for single-line, `n` for an upper bound on lines (auto-grows up to it).
    var lineLimit: Int? = nil

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 8) {
            Group {
                if let limit = lineLimit {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(1...limit)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(font)
            .tracking(tracking)
            .lineSpacing(lineSpacing)
            .multilineTextAlignment(.center)
            .foregroundStyle(color)
            .tint(underlineColor)
            .autocorrectionDisabled(false)
            .focused($focused)

            Rectangle()
                .fill(underlineColor)
                .frame(height: 1)
        }
        .frame(maxWidth: maxWidth)
        .onAppear { focused = true }
    }

    private var font: Font {
        let base = Font.system(size: fontSize, weight: weight, design: .serif)
        return italic ? base.italic() : base
    }
}
