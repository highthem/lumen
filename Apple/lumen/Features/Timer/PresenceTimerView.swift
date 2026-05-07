import SwiftUI

struct PresenceTimerView: View {
    @State var vm: PresenceTimerViewModel
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Eyebrow("Présence · 60 secondes")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, LumenSpacing.xl)

                Spacer()

                VStack(spacing: LumenSpacing.xxl) {
                    if let quote = vm.quote {
                        VStack(spacing: LumenSpacing.sm2) {
                            Text(quote.text)
                                .lumenFont(.title2)
                                .fontWeight(.regular)
                                .lineSpacing(LumenLineSpacing.l)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(LumenColor.textPrimary)
                                .frame(maxWidth: LumenSize.cardForm)

                            if let author = quote.author {
                                Text("— \(author)")
                                    .lumenFont(.caption)
                                    .textCase(.uppercase)
                                    .foregroundStyle(LumenColor.textTertiary)
                            }
                        }
                    }

                    BreathingCircle()
                }

                Spacer()

                HStack {
                    Spacer()
                    GhostCTA(title: "Passer →") {
                        vm.skip()
                    }
                    .accessibilityIdentifier("presence-timer-skip-button")
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
                LumenHaptic.timerEnd()
                onComplete()
            }
        }
        .accessibilityIdentifier("presence-timer-screen")
    }
}
