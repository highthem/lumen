import SwiftUI

struct Q3GratitudeView: View {
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
            ProgressDots4(current: 2)

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("03 / 04 · Gratitude")
                Text("Une gratitude ?")
                    .font(.system(size: 30, weight: .medium, design: .serif))
                    .tracking(-0.45)
                    .foregroundStyle(LumenColor.textPrimary)
            }

            VStack(spacing: 36) {
                Spacer(minLength: 0)
                revealArea
                if state != .editing {
                    micArea
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            ghostActionsRow
                .frame(maxWidth: .infinity, minHeight: 32)

            FooterRow(
                backTitle: "Retour",
                nextTitle: "Suivant",
                isNextEnabled: !vm.gratitudeText.isEmpty && state != .listening,
                onBack: onBack,
                onNext: onNext
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, 28)
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
                    font: .system(size: 28, weight: .medium, design: .serif),
                    color: LumenColor.accent,
                    isItalic: false,
                    charDelay: .milliseconds(38)
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            case .transcribed:
                Text(vm.gratitudeText)
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .tracking(-0.42)
                    .lineSpacing(2)
                    .foregroundStyle(LumenColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

            case .editing:
                editingPanel
            }
        }
        .frame(minHeight: 130)
    }

    // MARK: - Mic area

    @ViewBuilder
    private var micArea: some View {
        VStack(spacing: 14) {
            MicCTA(
                isListening: state == .listening,
                onPressDown: { vm.startDictation(for: .gratitude) },
                onPressUp: { Task { await vm.stopDictation(for: .gratitude) } }
            )

            switch state {
            case .default:
                VStack(spacing: 4) {
                    Text("Tap pour parler")
                        .font(.system(size: 15, weight: .medium))
                        .tracking(-0.075)
                        .foregroundStyle(LumenColor.textPrimary.opacity(0.75))
                    Button {
                        vm.editingByKeyboard = true
                    } label: {
                        Text("ou écrire au clavier")
                            .font(.system(size: 13, design: .serif))
                            .italic()
                            .foregroundStyle(LumenColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

            case .listening:
                HStack(spacing: 8) {
                    Circle()
                        .fill(LumenColor.accent)
                        .frame(width: 7, height: 7)
                    Text("on écoute")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LumenColor.accent.opacity(0.85))
                }

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Ghost action row

    @ViewBuilder
    private var ghostActionsRow: some View {
        HStack(spacing: 24) {
            switch state {
            case .default:
                // The keyboard fallback lives below the mic now; this row stays empty.
                EmptyView()

            case .listening:
                Spacer()
                Button {
                    Task { await vm.stopDictation(for: .gratitude) }
                } label: {
                    Text("Annuler")
                        .font(.system(size: 13))
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Spacer()

            case .transcribed:
                Spacer()
                Button {
                    vm.resetGratitude()
                } label: {
                    Text("↺ Recommencer")
                        .font(.system(size: 13))
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Button {
                    vm.editingByKeyboard = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 13))
                        Text("Modifier")
                            .font(.system(size: 13))
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
                        .font(.system(size: 13, design: .serif))
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
            fontSize: 22,
            tracking: -0.33,
            lineSpacing: 2,
            lineLimit: 4
        )
    }
}
