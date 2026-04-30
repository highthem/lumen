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
                    .padding(.top, 36)

                Spacer()

                VStack(spacing: 48) {
                    if let quote = vm.quote {
                        VStack(spacing: 12) {
                            Text(quote.text)
                                .font(.system(size: 26, weight: .regular, design: .serif))
                                .tracking(-0.26)
                                .lineSpacing(6)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(LumenColor.textPrimary)
                                .frame(maxWidth: 280)

                            if let author = quote.author {
                                Text("— \(author)")
                                    .font(.system(size: 12))
                                    .tracking(2)
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
