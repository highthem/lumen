import SwiftUI
import UIKit

struct SynthesisView: View {
    @State var vm: SynthesisViewModel
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealedBlocks: Int = 0

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
                    case .missingAPIKey:
                        missingKeyView
                    case .error(let msg):
                        errorView(msg: msg)
                    }
                }
                .padding(.horizontal, LumenSpacing.l)
                .padding(.vertical, LumenSpacing.l)
            }
        }
        .task { await vm.load() }
        .onDisappear {
            // Speech synthesis is on a long-lived AVSpeechSynthesizer; without
            // an explicit stop here the voice keeps reading after the screen
            // is dismissed (continuer / regenerate).
            Task { await vm.stopTTS() }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: LumenSpacing.heroLg)
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
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            // Top header: "Ton matin" eyebrow + on-device badge when relevant.
            // The listen control moves to a full-width premium player below.
            VStack(alignment: .leading, spacing: LumenSpacing.xs2) {
                HStack(alignment: .center) {
                    Eyebrow("Ton matin")
                    Spacer()
                    if response.provider == .apple {
                        AppleIntelligenceBadge(shimmer: true)
                    }
                }
                Text(headerDateLabel)
                    .lumenFont(.title1)
                    .foregroundStyle(LumenColor.textPrimary)
            }

            // Three synthesis blocks (reading focus dims non-current ones during TTS)
            VStack(alignment: .leading, spacing: LumenSpacing.l) {
                intentionBlock(text: response.intention, isSupport: response.provider == .supportTemplate)

                if !response.focus.isEmpty {
                    focusBlock(text: response.focus.joined(separator: "\n"))
                }

                reminderBlock(text: response.reminder, isSupport: response.provider == .supportTemplate)
            }
            .task(id: response.id) {
                await runRevealSequence()
            }

            Spacer(minLength: LumenSpacing.m)

            // Premium full-width listen player (V8 signature)
            ListenPlayer(
                isPlaying: vm.ttsPlaying,
                progress: ttsProgress,
                durationLabel: "≈ 38 s",
                elapsedLabel: vm.ttsPlaying ? "Lecture · paragraphe \(vm.ttsCurrentBlock + 1) sur 3" : nil,
                onTap: { Task { await vm.toggleTTS() } }
            )

            // Footer actions
            VStack(alignment: .leading, spacing: LumenSpacing.m) {
                if !vm.ttsPlaying {
                    HStack(spacing: LumenSpacing.sm2) {
                        SecondaryCTA(
                            "Régénérer",
                            isEnabled: vm.remainingRegens > 0
                        ) {
                            Task { await vm.regenerate() }
                        }
                        PrimaryCTA("Continuer →") {
                            onComplete()
                        }
                    }

                    Text("Régénérations · \(vm.remainingRegens) / 3 restantes")
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    PrimaryCTA("Continuer →") {
                        onComplete()
                    }
                }
            }
        }
    }

    private var headerDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM."
        return formatter.string(from: Date()).capitalized
    }

    private var ttsProgress: Double {
        guard vm.ttsPlaying else { return 0 }
        // 3-block synthesis — block index gives a coarse-grained progress
        // until the speech synthesizer exposes elapsed time.
        return (Double(vm.ttsCurrentBlock) + 0.5) / 3.0
    }

    private func intentionBlock(text: String, isSupport: Bool) -> some View {
        synthesisBlock(blockIndex: 0) {
            Eyebrow("Intention")
            Text(text)
                .lumenFont(.synthesisHero)
                .italic()
                .foregroundStyle(LumenColor.accent)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func focusBlock(text: String) -> some View {
        synthesisBlock(blockIndex: 1, showBreathDot: vm.ttsPlaying && vm.ttsCurrentBlock == 1) {
            HStack(spacing: LumenSpacing.s) {
                Eyebrow("Focus")
                if vm.ttsPlaying && vm.ttsCurrentBlock == 1 {
                    Circle()
                        .fill(LumenColor.accent)
                        .frame(width: LumenSize.dotSm, height: LumenSize.dotSm)
                }
            }
            Text(text)
                .lumenFont(.bodySerifLg)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func reminderBlock(text: String, isSupport: Bool) -> some View {
        synthesisBlock(blockIndex: 2) {
            Eyebrow("Rappel")
            Text(text)
                .lumenFont(.bodySerif)
                .italic()
                .lineSpacing(LumenLineSpacing.xs)
                .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.pressed))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func synthesisBlock<Content: View>(
        blockIndex: Int,
        showBreathDot: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isActive = !vm.ttsPlaying || vm.ttsCurrentBlock == blockIndex
        let isRevealed = revealedBlocks > blockIndex
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            content()
        }
        .opacity(isRevealed ? (isActive ? 1.0 : LumenOpacity.p32) : 0)
        .offset(y: isRevealed ? 0 : LumenSpacing.sm2)
        .animation(reduceMotion ? LumenAnimation.standard : LumenAnimation.decelerateLong, value: revealedBlocks)
        .animation(LumenAnimation.standard, value: vm.ttsCurrentBlock)
        .animation(LumenAnimation.standard, value: vm.ttsPlaying)
    }

    /// Spec reveal: 3 blocks fade-in + slide-up 12pt, 250ms cumulative delay,
    /// 400ms per block (decelerate). Reduce motion → single 300ms fade.
    /// Fires `LumenHaptic.synthesisReady()` once the last block lands.
    private func runRevealSequence() async {
        revealedBlocks = 0
        if reduceMotion {
            withAnimation(LumenAnimation.standard) { revealedBlocks = 3 }
            try? await Task.sleep(for: LumenDelay.pauseLong)
        } else {
            for index in 1...3 {
                try? await Task.sleep(for: LumenDelay.pause)
                withAnimation(LumenAnimation.decelerateLong) { revealedBlocks = index }
            }
            try? await Task.sleep(for: LumenDelay.settle)
        }
        LumenHaptic.synthesisReady()
    }

    // MARK: - Queued

    private var queuedView: some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: LumenSpacing.xxh)
            SlowPulse()
            Text("Ta synthèse arrive")
                .lumenFont(.title2)
                .fontWeight(.regular)
                .foregroundStyle(LumenColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("On te notifie dès que ton réseau revient.")
                .lumenFont(.footnote)
                .foregroundStyle(LumenColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: LumenSize.blockSm)
            PrimaryCTA("Continuer vers le dashboard") {
                onComplete()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rate limited

    private var rateLimitedView: some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: LumenSpacing.xxh)
            Text("Limite atteinte pour aujourd'hui — reviens demain.")
                .lumenFont(.title3)
                .fontWeight(.regular)
                .foregroundStyle(LumenColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: LumenSize.blockSm)
            PrimaryCTA("Continuer vers le dashboard") {
                onComplete()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Missing API key

    private var missingKeyView: some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: LumenSpacing.xxh)
            Text("Clés API manquantes")
                .lumenFont(.title2)
                .fontWeight(.regular)
                .foregroundStyle(LumenColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("Renseigne les clés OpenAI / Anthropic dans les Réglages pour activer la synthèse.")
                .lumenFont(.footnote)
                .foregroundStyle(LumenColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LumenSpacing.l)
            SecondaryCTA("Ouvrir les Réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Spacer(minLength: LumenSpacing.l)
            PrimaryCTA("Continuer vers le dashboard") {
                onComplete()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error

    private func errorView(msg: String) -> some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: LumenSpacing.xxh)
            Text(msg)
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
                .multilineTextAlignment(.center)
            SecondaryCTA("Réessayer") {
                Task { await vm.load() }
            }
            Spacer(minLength: LumenSize.blockSm)
        }
        .frame(maxWidth: .infinity)
    }
}
