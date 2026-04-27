import SwiftUI

struct KineticText: View {
    let words: [String]
    var stagger: Duration = .milliseconds(110)
    var rise: Duration = .milliseconds(900)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleCount: Int = 0

    init(_ words: [String]) {
        self.words = words
    }

    var body: some View {
        Text(displayString)
            .multilineTextAlignment(.leading)
            .lineSpacing(0)
            .task(id: words) {
                if reduceMotion {
                    visibleCount = words.count
                    return
                }
                visibleCount = 0
                for index in words.indices {
                    if Task.isCancelled { return }
                    visibleCount = index + 1
                    try? await Task.sleep(for: stagger)
                }
            }
            .animation(.easeOut(duration: TimeInterval(rise.components.seconds)), value: visibleCount)
    }

    private var displayString: String {
        words.prefix(visibleCount).joined(separator: " ")
    }
}
