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

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("04 / 04 · Intention")
                Text("Ton intention\nen un mot.")
                    .font(.system(size: 30, weight: .medium, design: .serif))
                    .tracking(-0.45)
                    .lineSpacing(-2)
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
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
                nextTitle: "Voir ma synthèse",
                isNextEnabled: !vm.intentionWord.isEmpty && state != .listening,
                onBack: onBack,
                onNext: onNext
            )
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.top, 28)
        .padding(.bottom, LumenSpacing.l)
    }

    @ViewBuilder
    private var revealArea: some View {
        ZStack {
            switch state {
            case .default:
                Text("Dis-le…")
                    .font(.system(size: 19, design: .serif))
                    .italic()
                    .foregroundStyle(LumenColor.textPrimary.opacity(0.42))

            case .listening:
                LiveTranscript(
                    text: vm.intentionWord,
                    font: .system(size: 64, weight: .medium, design: .serif),
                    color: LumenColor.accent,
                    isItalic: true,
                    charDelay: .milliseconds(120)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            case .transcribed:
                Text(vm.intentionWord)
                    .font(.system(size: 64, weight: .medium, design: .serif))
                    .italic()
                    .tracking(-1.28)
                    .foregroundStyle(LumenColor.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

            case .editing:
                editingPanel
            }
        }
        .frame(minHeight: 130)
    }

    @ViewBuilder
    private var micArea: some View {
        VStack(spacing: 12) {
            MicCTA(
                isListening: state == .listening,
                onPressDown: { vm.startDictation(for: .intention) },
                onPressUp: { Task { await vm.stopDictation(for: .intention) } }
            )

            if state == .listening {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LumenColor.accent)
                        .frame(width: 5, height: 5)
                    Text("on écoute")
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundStyle(LumenColor.accent.opacity(0.7))
                }
            }
        }
    }

    @ViewBuilder
    private var ghostActionsRow: some View {
        HStack(spacing: 24) {
            switch state {
            case .default:
                Spacer()
                Button {
                    vm.intentionEditingByKeyboard = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 13))
                        Text("Écrire au clavier")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Spacer()

            case .listening:
                Spacer()
                Button {
                    Task { await vm.stopDictation(for: .intention) }
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
                    vm.resetIntention()
                } label: {
                    Text("↺ Recommencer")
                        .font(.system(size: 13))
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Button {
                    vm.intentionEditingByKeyboard = true
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
                    vm.intentionEditingByKeyboard = false
                } label: {
                    Text("Tu peux aussi reparler →")
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundStyle(LumenColor.textSecondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
    }

    private var editingPanel: some View {
        TextField("présence", text: $vm.intentionWord)
            .multilineTextAlignment(.center)
            .font(.system(size: 64, weight: .medium, design: .serif))
            .italic()
            .tracking(-1.12)
            .foregroundStyle(LumenColor.accent)
            .padding(.bottom, 8)
            .overlay(
                Rectangle()
                    .fill(LumenColor.accent)
                    .frame(height: 1)
                    .padding(.horizontal, 30),
                alignment: .bottom
            )
            .frame(maxWidth: 280)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }
}
