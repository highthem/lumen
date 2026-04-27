import SwiftUI

struct PresenceTimerView: View {
    @State var vm: PresenceTimerViewModel
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                BreathingCircle()
                    .padding(.bottom, LumenSpacing.xl)

                if let quote = vm.quote {
                    Text(quote.text)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .italic()
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .foregroundStyle(LumenColor.textPrimary.opacity(0.75))
                        .padding(.horizontal, LumenSpacing.xl)
                        .padding(.bottom, LumenSpacing.s)

                    if let author = quote.author {
                        Text("— \(author)")
                            .lumenFont(.caption)
                            .foregroundStyle(LumenColor.textTertiary)
                    }
                }

                Spacer()

                GhostCTA(title: "Passer") {
                    vm.skip()
                }
                .padding(.bottom, LumenSpacing.l)
            }
            .padding(.horizontal, LumenSpacing.l)
        }
        .task {
            await vm.start()
        }
        .onChange(of: vm.isComplete) { _, completed in
            if completed {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                onComplete()
            }
        }
    }
}
