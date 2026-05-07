import SwiftUI

struct LiveTranscript: View {
    let text: String
    let font: LumenFont
    let color: Color
    var isItalic: Bool = false
    var charDelay: Duration = LumenDelay.charSlow

    @State private var visibleCount: Int = 0
    @State private var revealTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(String(text.prefix(visibleCount)))
            .lumenFont(font)
            .italic(isItalic)
            .foregroundStyle(color)
            .onChange(of: text) { _, newText in
                revealTask?.cancel()
                if reduceMotion {
                    visibleCount = newText.count
                } else {
                    revealTask = Task {
                        await revealCharacters(in: newText)
                    }
                }
            }
            .onAppear {
                if reduceMotion {
                    visibleCount = text.count
                } else {
                    revealTask = Task {
                        await revealCharacters(in: text)
                    }
                }
            }
    }

    private func revealCharacters(in target: String) async {
        let targetCount = target.count
        while visibleCount < targetCount {
            guard !Task.isCancelled else { return }
            visibleCount += 1
            try? await Task.sleep(for: charDelay)
        }
    }
}

#if DEBUG
#Preview {
    LiveTranscript(
        text: "Trois choses à honorer ce matin avant de plonger.",
        font: .bodySerif,
        color: LumenColor.textPrimary,
        isItalic: true
    )
    .padding(LumenSpacing.l)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(LumenColor.bgPrimary)
}
#endif
