import SwiftUI

struct SynthesisView: View {
    @State var vm: SynthesisViewModel
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    switch vm.state {
                    case .loading:
                        loadingView
                    case .ready(let response):
                        readyView(response: response)
                    case .queued:
                        queuedView
                    case .rateLimited:
                        rateLimitedView
                    case .error(let msg):
                        errorView(msg: msg)
                    }
                }
                .padding(.horizontal, LumenSpacing.l)
                .padding(.vertical, LumenSpacing.l)
            }
        }
        .task { await vm.load() }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: 120)
            ProgressView()
                .tint(LumenColor.accent)
            Text("Ton matin se prépare…")
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ready

    private func readyView(response: AIResponse) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.xl) {
            // Speaker + optional badge
            HStack {
                SpeakerButton(isPlaying: vm.ttsPlaying) {
                    Task { await vm.toggleTTS() }
                }
                Spacer()
                if response.provider == .apple {
                    AppleIntelligenceBadge(shimmer: true)
                }
            }

            // Three synthesis blocks
            synthesisBlock(
                eyebrow: "INTENTION",
                text: response.intention,
                blockIndex: 0,
                isSupportTemplate: response.provider == .supportTemplate
            )

            if !response.focus.isEmpty {
                synthesisBlock(
                    eyebrow: "FOCUS",
                    text: response.focus.joined(separator: "\n"),
                    blockIndex: 1,
                    isSupportTemplate: false
                )
            }

            synthesisBlock(
                eyebrow: "RAPPEL",
                text: response.reminder,
                blockIndex: 2,
                isSupportTemplate: response.provider == .supportTemplate
            )

            // Regenerate + Continue
            VStack(spacing: LumenSpacing.m) {
                SecondaryCTA(
                    "Régénérer (\(vm.remainingRegens)/3)",
                    isEnabled: vm.remainingRegens > 0
                ) {
                    Task { await vm.regenerate() }
                }

                PrimaryCTA("Continuer vers le dashboard") {
                    onComplete()
                }
            }
        }
    }

    private func synthesisBlock(
        eyebrow: String,
        text: String,
        blockIndex: Int,
        isSupportTemplate: Bool
    ) -> some View {
        let isActive = !vm.ttsPlaying || vm.ttsCurrentBlock == blockIndex
        return VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow(eyebrow)
            Text(text)
                .font(.system(
                    size: isSupportTemplate ? 20 : 18,
                    weight: isSupportTemplate ? .semibold : .regular,
                    design: .serif
                ))
                .foregroundStyle(LumenColor.textPrimary)
                .lineSpacing(LumenFont.title2.lineSpacing)
        }
        .opacity(isActive ? 1.0 : 0.32)
        .animation(.easeInOut(duration: 0.6), value: vm.ttsCurrentBlock)
    }

    // MARK: - Queued

    private var queuedView: some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: 80)
            SlowPulse()
            Text("Ta synthèse arrive")
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundStyle(LumenColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("On te notifie dès que ton réseau revient.")
                .lumenFont(.footnote)
                .foregroundStyle(LumenColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 40)
            PrimaryCTA("Continuer vers le dashboard") {
                onComplete()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rate limited

    private var rateLimitedView: some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: 80)
            Text("Limite atteinte pour aujourd'hui — reviens demain.")
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(LumenColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 40)
            PrimaryCTA("Continuer vers le dashboard") {
                onComplete()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error

    private func errorView(msg: String) -> some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: 80)
            Text(msg)
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
                .multilineTextAlignment(.center)
            SecondaryCTA("Réessayer") {
                Task { await vm.load() }
            }
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }
}
