import SwiftUI

struct Q4IntentionView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    private enum LocalState { case `default`, listening, transcribed, editing }

    private var state: LocalState {
        if vm.intentionEditingByKeyboard { return .editing }
        if vm.intentionMicState == .listening { return .listening }
        if !vm.intentionWord.isEmpty { return .transcribed }
        return .default
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            ProgressDots4(current: 3)

            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                Eyebrow("04 / 04 · Intention")
                Text("Ton intention\nen un mot.")
                    .lumenFont(.title1)
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: LumenSpacing.xl2) {
                Spacer(minLength: 0)
                revealArea
                if state != .editing {
                    micArea
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            ghostActionsRow
                .frame(maxWidth: .infinity, minHeight: LumenSize.blockMin)

            FooterRow(
                backTitle: "Retour",
                nextTitle: "Voir ma synthèse",
                isNextEnabled: !vm.intentionWord.isEmpty && state != .listening,
                onBack: onBack,
                onNext: onNext
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, LumenSpacing.xl0)
        .padding(.bottom, LumenSpacing.l)
    }

    @ViewBuilder
    private var revealArea: some View {
        ZStack {
            switch state {
            case .default:
                // Default — empty reveal area; mic + labels carry the CTA.
                Color.clear

            case .listening:
                LiveTranscript(
                    text: vm.intentionWord,
                    font: .questionnaireHero,
                    color: LumenColor.accent,
                    isItalic: true,
                    charDelay: LumenDelay.pulse
                )
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            case .transcribed:
                Text(vm.intentionWord)
                    .lumenFont(.heroDisplay)
                    .italic()
                    .foregroundStyle(LumenColor.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

            case .editing:
                editingPanel
            }
        }
        .frame(minHeight: LumenSize.blockReveal)
    }

    @ViewBuilder
    private var micArea: some View {
        VStack(spacing: LumenSpacing.sm3) {
            MicCTA(
                isListening: state == .listening,
                onPressDown: { vm.startDictation(for: .intention) },
                onPressUp: { Task { await vm.stopDictation(for: .intention) } },
                accessibilityID: "mic-button"
            )

            switch state {
            case .default:
                VStack(spacing: LumenSpacing.xs) {
                    Text("Tap pour parler")
                        .lumenFont(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.waveform))
                    Button {
                        vm.intentionEditingByKeyboard = true
                    } label: {
                        Text("ou écrire au clavier")
                            .lumenFont(.footnoteSerif)
                            .italic()
                            .foregroundStyle(LumenColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("intention-keyboard-toggle")
                }

            case .listening:
                HStack(spacing: LumenSpacing.s) {
                    Circle()
                        .fill(LumenColor.accent)
                        .frame(width: LumenSize.dotLg, height: LumenSize.dotLg)
                    Text("on écoute")
                        .lumenFont(.footnote)
                        .fontWeight(.medium)
                        .foregroundStyle(LumenColor.accent.opacity(LumenOpacity.pressed))
                }

            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var ghostActionsRow: some View {
        HStack(spacing: LumenSpacing.l) {
            switch state {
            case .default:
                // The keyboard fallback lives below the mic now; this row stays empty.
                EmptyView()

            case .listening:
                Spacer()
                Button {
                    Task { await vm.stopDictation(for: .intention) }
                } label: {
                    Text("Annuler")
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("intention-keyboard-toggle")
                Spacer()

            case .transcribed:
                Spacer()
                Button {
                    vm.resetIntention()
                } label: {
                    Text("↺ Recommencer")
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Button {
                    vm.intentionEditingByKeyboard = true
                } label: {
                    HStack(spacing: LumenSpacing.xs2) {
                        Image(systemName: "keyboard")
                            .font(LumenIconFont.md)
                        Text("Modifier")
                            .lumenFont(.footnote)
                    }
                    .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Spacer()

            case .editing:
                Spacer()
                Button {
                    vm.intentionEditingByKeyboard = false
                } label: {
                    Text("← Tu peux aussi reparler")
                        .lumenFont(.footnoteSerif)
                        .italic()
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
    }

    private var editingPanel: some View {
        SerifUnderlineField(
            text: $vm.intentionWord,
            placeholder: "présence",
            font: .questionnaireHero,
            color: LumenColor.accent,
            maxWidth: LumenSize.cardForm,
            accessibilityID: "intention-textfield"
        )
    }
}
