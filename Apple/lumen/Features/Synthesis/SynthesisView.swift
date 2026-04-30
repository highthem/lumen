import SwiftUI
import UIKit

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
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            // Top header: "Ton matin" eyebrow + on-device badge when relevant.
            // The listen control moves to a full-width premium player below.
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Eyebrow("Ton matin")
                    Spacer()
                    if response.provider == .apple {
                        AppleIntelligenceBadge(shimmer: true)
                    }
                }
                Text(headerDateLabel)
                    .font(.system(size: 30, weight: .medium, design: .serif))
                    .tracking(-0.30)
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

            Spacer(minLength: 16)

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
                    HStack(spacing: 12) {
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
                        .font(.system(size: 12))
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
                .font(.system(size: 42, weight: .medium, design: .serif))
                .italic()
                .tracking(-0.84)
                .lineSpacing(-2)
                .foregroundStyle(LumenColor.accent)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func focusBlock(text: String) -> some View {
        synthesisBlock(blockIndex: 1, showBreathDot: vm.ttsPlaying && vm.ttsCurrentBlock == 1) {
            HStack(spacing: 8) {
                Eyebrow("Focus")
                if vm.ttsPlaying && vm.ttsCurrentBlock == 1 {
                    Circle()
                        .fill(LumenColor.accent)
                        .frame(width: 5, height: 5)
                }
            }
            Text(text)
                .font(.system(size: 19, design: .serif))
                .tracking(-0.095)
                .lineSpacing(2)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func reminderBlock(text: String, isSupport: Bool) -> some View {
        synthesisBlock(blockIndex: 2) {
            Eyebrow("Rappel")
            Text(text)
                .font(.system(size: 17, design: .serif))
                .italic()
                .lineSpacing(2)
                .foregroundStyle(LumenColor.textPrimary.opacity(0.85))
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
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .opacity(isActive ? 1.0 : 0.32)
        .animation(.easeInOut(duration: 0.6), value: vm.ttsCurrentBlock)
        .animation(.easeInOut(duration: 0.6), value: vm.ttsPlaying)
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

    // MARK: - Missing API key

    private var missingKeyView: some View {
        VStack(spacing: LumenSpacing.m) {
            Spacer(minLength: 80)
            Text("Clés API manquantes")
                .font(.system(size: 22, weight: .regular, design: .serif))
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
            Spacer(minLength: 24)
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
