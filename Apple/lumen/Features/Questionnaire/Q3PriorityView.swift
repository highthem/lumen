import SwiftUI

/// Q3 — Priorité (V11 voice-first). Structurally a copy of Q4Gratitude:
/// tap mic → écoute → transcript → édition. Replaces the V8-V10 CardDeck of
/// `PriorityCategory` choices. Free-text answer up to ~140 characters.
struct Q3PriorityView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    private enum LocalState { case `default`, listening, transcribed, editing }

    private var state: LocalState {
        if vm.priorityEditingByKeyboard { return .editing }
        if vm.priorityMicState == .listening { return .listening }
        if !vm.priorityText.isEmpty { return .transcribed }
        return .default
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            ProgressDots4(current: 2)

            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                Eyebrow("03 / 04 · Priorité")
                Text("À quoi tu veux\nposer l'attention\naujourd'hui ?")
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
                .padding(.bottom)
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, LumenSpacing.xl0)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FooterRow(
                backTitle: "Retour",
                nextTitle: "Suivant",
                isNextEnabled: !vm.priorityText.isEmpty && state != .listening,
                onBack: onBack,
                onNext: onNext
            )
            .padding(.horizontal, LumenSpacing.l)
            .padding(.bottom, LumenSpacing.l)
            .background(LumenColor.bgPrimary)
        }
    }

    // MARK: - Reveal area (above mic)

    @ViewBuilder
    private var revealArea: some View {
        ZStack {
            switch state {
            case .default:
                Color.clear

            case .listening:
                LiveTranscript(
                    text: vm.priorityText.isEmpty ? "" : vm.priorityText,
                    font: .questionnaireQM,
                    color: LumenColor.accent,
                    isItalic: false,
                    charDelay: LumenDelay.charStagger
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: LumenSize.cardField)

            case .transcribed:
                Text(vm.priorityText)
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
                onPressDown: { vm.startDictation(for: .priority) },
                onPressUp: { Task { await vm.finishDictation(for: .priority) } },
                accessibilityID: "priority-mic"
            )

            switch state {
            case .default:
                VStack(spacing: LumenSpacing.xs) {
                    Text("Tap pour parler")
                        .lumenFont(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.waveform))
                    Button {
                        vm.priorityEditingByKeyboard = true
                    } label: {
                        Text("ou écrire au clavier")
                            .lumenFont(.footnoteSerif)
                            .italic()
                            .foregroundStyle(LumenColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("priority-keyboard-toggle")
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
                EmptyView()

            case .listening:
                Spacer()
                Button {
                    Task { await vm.cancelDictation(for: .priority) }
                } label: {
                    Text("Annuler")
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("priority-cancel")
                Spacer()

            case .transcribed:
                Spacer()
                Button {
                    vm.resetPriority()
                } label: {
                    Text("↺ Recommencer")
                        .lumenFont(.footnote)
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Button {
                    vm.priorityEditingByKeyboard = true
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
                    vm.priorityEditingByKeyboard = false
                } label: {
                    Text("← Tu peux aussi reparler")
                        .lumenFont(.footnoteSerif)
                        .italic()
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("priority-return-to-voice")
                Spacer()
            }
        }
    }

    // MARK: - Editing panel

    private var editingPanel: some View {
        SerifUnderlineField(
            text: $vm.priorityText,
            placeholder: "Une chose qui compte aujourd'hui.",
            font: .inputSerifLg,
            lineLimit: 4,
            accessibilityID: "priority-textarea"
        )
    }
}

#if DEBUG
#Preview("Default") {
    Q3PriorityView(vm: .preview, onNext: {}, onBack: {})
        .preferredColorScheme(.dark)
}
#endif
