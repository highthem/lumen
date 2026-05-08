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
        .accessibilityIdentifier("synthesis-screen")
        .onDisappear {
            // Cancels any in-flight cloud synthesis + TTS playback so we
            // don't leak network requests or keep the AVSpeechSynthesizer
            // talking after the cover dismisses.
            vm.dispose()
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
            // Top header: "Ton matin" eyebrow + provider badge (Cloud / AI / Queued).
            VStack(alignment: .leading, spacing: LumenSpacing.xs2) {
                HStack(alignment: .center) {
                    Eyebrow("Ton matin")
                    Spacer()
                    ProviderBadge(kind: badgeKind(for: response))
                }
                Text(headerDateLabel)
                    .lumenFont(.title1)
                    .foregroundStyle(LumenColor.textPrimary)
            }

            // V11 hero: 42pt serif italic quote (the response's `heroQuote`,
            // which surfaces the prompt's calm `intention` line).
            heroQuoteBlock(
                text: response.heroQuote,
                isSupport: response.provider == .supportTemplate
            )
            .task(id: response.id) {
                await runRevealSequence()
            }

            // Below the hero: focus + reminder rendered as flowing prose
            // (no eyebrows, smaller serif, dimmed) per the design strip.
            // The TTS narrates these out loud.
            supplementaryBlocks(response: response)

            Spacer(minLength: LumenSpacing.m)

            // Premium full-width listen player (V8 signature). Progress + labels
            // are now driven by AVSpeechSynthesizer's word-boundary delegate
            // (FR Audrey ~13 chars/sec) — bar tracks the actual narration
            // and the elapsed/total countdown updates in real time.
            Spacer()
            ListenPlayer(
                isPlaying: vm.ttsPlaying,
                progress: ttsProgress,
                durationLabel: formatTime(vm.ttsDuration > 0 ? vm.ttsDuration : 38),
                elapsedLabel: vm.ttsPlaying ? formatTime(vm.ttsElapsed) : nil,
                onTap: { Task { await vm.toggleTTS() } },
                accessibilityID: "synthesis-listen-button"
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
                        .accessibilityIdentifier("synthesis-continue-button")
                    }

                    Text("Régénérations · \(vm.remainingRegens) / 3 restantes")
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    PrimaryCTA("Continuer →") {
                        onComplete()
                    }
                    .accessibilityIdentifier("synthesis-continue-button")
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
        guard vm.ttsPlaying, vm.ttsDuration > 0 else { return 0 }
        return min(1.0, max(0.0, vm.ttsElapsed / vm.ttsDuration))
    }

    /// "0:38" for sub-minute, "1:24" for longer. Used for both elapsed and
    /// total labels in the listen-player pill.
    private func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    /// Maps an AIResponse provider to the badge kind shown in the top-right
    /// slot. Cloud providers (OpenAI/Anthropic/supportTemplate) intentionally
    /// have no badge — Apple Intelligence and Queued are surfaced explicitly.
    private func badgeKind(for response: AIResponse) -> ProviderBadge.Kind {
        switch response.provider {
        case .apple:           return .appleIntelligence
        case .queued:          return .queued
        case .openai, .anthropic, .supportTemplate:
            return .cloud
        }
    }

    /// Focus + reminder rendered below the hero quote as flowing serif prose.
    /// Per the V11 mock strip — no labelled blocks, just two paragraphs that
    /// recede visually but support the TTS narration.
    @ViewBuilder
    private func supplementaryBlocks(response: AIResponse) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.m) {
            if !response.focus.isEmpty {
                Text(response.focus.joined(separator: "\n"))
                    .lumenFont(.bodySerif)
                    .lineSpacing(LumenLineSpacing.s)
                    .foregroundStyle(LumenColor.textPrimary)
                    .frame(maxWidth: LumenSize.heroQuoteMax, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("synthesis-focus")
            }
            if !response.reminder.isEmpty {
                Text(response.reminder)
                    .lumenFont(.bodySerif)
                    .italic()
                    .lineSpacing(LumenLineSpacing.s)
                    .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.pressed))
                    .frame(maxWidth: LumenSize.heroQuoteMax, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("synthesis-reminder")
            }
        }
        .opacity(revealedBlocks > 0 ? 1 : 0)
        .animation(reduceMotion ? LumenAnimation.standard : LumenAnimation.decelerateLong, value: revealedBlocks)
    }

    /// V11 single hero quote — 48pt serif italic, accent color (or muted if
    /// support template), centered with a max width so long quotes wrap
    /// nicely on iPad without becoming a paragraph.
    private func heroQuoteBlock(text: String, isSupport: Bool) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow("Intention")
            Text(text)
                .lumenFont(.synthesisHero)
                .italic()
                .multilineTextAlignment(.leading)
                .foregroundStyle(isSupport ? LumenColor.textPrimary : LumenColor.accent)
                .frame(maxWidth: LumenSize.heroQuoteMax, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(revealedBlocks > 0 ? 1 : 0)
        .offset(y: revealedBlocks > 0 ? 0 : LumenSpacing.sm2)
        .animation(reduceMotion ? LumenAnimation.standard : LumenAnimation.decelerateLong, value: revealedBlocks)
        .accessibilityIdentifier("synthesis-hero-quote")
    }

    /// Single fade+slide for the hero quote. Reduce motion → simple opacity.
    /// Fires `LumenHaptic.synthesisReady()` once the reveal lands.
    private func runRevealSequence() async {
        revealedBlocks = 0
        if reduceMotion {
            withAnimation(LumenAnimation.standard) { revealedBlocks = 1 }
            try? await Task.sleep(for: LumenDelay.pauseLong)
        } else {
            try? await Task.sleep(for: LumenDelay.pause)
            withAnimation(LumenAnimation.decelerateLong) { revealedBlocks = 1 }
            try? await Task.sleep(for: LumenDelay.settle)
        }
        LumenHaptic.synthesisReady()
    }

    // MARK: - Queued

    private var queuedView: some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: LumenSpacing.xxh)
            SlowPulse()
            Spacer()
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
            .accessibilityIdentifier("synthesis-continue-button")
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
            .accessibilityIdentifier("synthesis-continue-button")
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
            .accessibilityIdentifier("synthesis-continue-button")
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

#if DEBUG
#Preview {
    SynthesisView(vm: .preview, onComplete: {})
        .preferredColorScheme(.dark)
}
#endif
