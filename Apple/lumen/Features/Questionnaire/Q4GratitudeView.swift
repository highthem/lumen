import SwiftUI

struct Q4GratitudeView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    private enum LocalState { case `default`, listening, transcribed, editing }

    private var state: LocalState {
        if vm.editingByKeyboard { return .editing }
        if vm.micState == .listening { return .listening }
        if !vm.gratitudeText.isEmpty { return .transcribed }
        return .default
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            ProgressDots4(current: 3)

            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                Eyebrow("04 / 04 · Gratitude")
                Text("Une gratitude ?")
                    .lumenFont(.title1)
                    .foregroundStyle(LumenColor.textPrimary)
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
                isNextEnabled: !vm.gratitudeText.isEmpty && state != .listening,
                onBack: onBack,
                onNext: onNext
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, LumenSpacing.xl0)
        .padding(.bottom, LumenSpacing.l)
    }

    // MARK: - Reveal area (above mic)

    @ViewBuilder
    private var revealArea: some View {
        ZStack {
            switch state {
            case .default:
                // Default — leave the reveal area empty; the mic + labels below
                // carry the call-to-action.
                Color.clear

            case .listening:
                LiveTranscript(
                    text: vm.gratitudeText.isEmpty ? "" : vm.gratitudeText,
                    font: .questionnaireQM,
                    color: LumenColor.accent,
                    isItalic: false,
                    charDelay: LumenDelay.charStagger
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: LumenSize.cardField)

            case .transcribed:
                Text(vm.gratitudeText)
                    .lumenFont(.questionnaireQM)
                    .foregroundStyle(LumenColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: LumenSize.cardField)

            case .editing:
                editingPanel
            }
        }
        .frame(minHeight: LumenSize.blockReveal)
    }

    // MARK: - Mic area

    @ViewBuilder
    private var micArea: some View {
        VStack(spacing: LumenSpacing.sm3) {
            MicCTA(
                isListening: state == .listening,
                onPressDown: { vm.startDictation(for: .gratitude) },
                onPressUp: { Task { await vm.finishDictation(for: .gratitude) } },
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
                        vm.editingByKeyboard = true
                    } label: {
                        Text("ou écrire au clavier")
                            .lumenFont(.footnoteSerif)
                            .italic()
                            .foregroundStyle(LumenColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("gratitude-keyboard-toggle")
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

    // MARK: - Ghost action row

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
                    Task { await vm.cancelDictation(for: .gratitude) }
                } label: {
                    Text("Annuler")
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("gratitude-keyboard-toggle")
                Spacer()

            case .transcribed:
                Spacer()
                Button {
                    vm.resetGratitude()
                } label: {
                    Text("↺ Recommencer")
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Button {
                    vm.editingByKeyboard = true
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
                    vm.editingByKeyboard = false
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

    // MARK: - Editing panel

    private var editingPanel: some View {
        SerifUnderlineField(
            text: $vm.gratitudeText,
            placeholder: "Le silence avant que les enfants se lèvent.",
            font: .inputSerifLg,
            lineLimit: 4,
            accessibilityID: "gratitude-textarea"
        )
    }
}
