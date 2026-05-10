import SwiftUI

struct PresenceTimerView: View {
    @State var vm: PresenceTimerViewModel
    /// Carries today's actual ritual ID to the next stage. The VM has already
    /// fetched-or-created the ritual by the time this fires, so the
    /// questionnaire downstream can skip its own redundant fetch.
    let onComplete: (UUID?) -> Void

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Eyebrow("Présence · \(Int(vm.totalDuration)) secondes")
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
        .onDisappear { vm.stop() }
        .onChange(of: vm.isComplete) { _, completed in
            if completed {
                LumenHaptic.timerEnd()
                onComplete(vm.ritualId)
            }
        }
        .accessibilityIdentifier("presence-timer-screen")
    }
}

#if DEBUG
#Preview {
    PresenceTimerView(vm: .preview, onComplete: { _ in })
        .preferredColorScheme(.dark)
}
#endif
