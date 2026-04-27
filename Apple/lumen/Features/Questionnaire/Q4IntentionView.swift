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
        VStack(alignment: .leading, spacing: 22) {
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

            VStack(spacing: 28) {
                Spacer(minLength: 0)
                centerStage
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

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
    private var centerStage: some View {
        if state == .editing {
            editingPanel
        } else if state == .transcribed {
            transcribedPanel
        } else {
            VStack(spacing: 14) {
                MicCTA(
                    isListening: state == .listening,
                    onPressDown: { vm.startDictation(for: .intention) },
                    onPressUp: { Task { await vm.stopDictation(for: .intention) } }
                )

                if state == .listening {
                    listeningSupport
                } else {
                    defaultSupport
                }
            }
        }
    }

    private var defaultSupport: some View {
        VStack(spacing: 4) {
            Text("Maintiens pour parler")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LumenColor.textPrimary.opacity(0.75))

            Button {
                vm.intentionEditingByKeyboard = true
            } label: {
                Text("ou écrire au clavier")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(LumenColor.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var listeningSupport: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(LumenColor.accent)
                    .frame(width: 7, height: 7)
                Text("on écoute")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LumenColor.accent)
            }

            if !vm.intentionWord.isEmpty {
                LiveTranscript(
                    text: vm.intentionWord,
                    font: .system(size: 56, weight: .medium, design: .serif),
                    color: LumenColor.accent,
                    isItalic: true,
                    charDelay: .milliseconds(130)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.4)
            }
        }
    }

    private var transcribedPanel: some View {
        VStack(spacing: 28) {
            Text(vm.intentionWord)
                .font(.system(size: 64, weight: .medium, design: .serif))
                .italic()
                .tracking(-1.28)
                .foregroundStyle(LumenColor.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            VStack(spacing: 10) {
                actionStackButton(systemImage: nil, glyph: "↺", label: "Refaire") {
                    vm.resetIntention()
                }
                actionStackButton(systemImage: "keyboard", glyph: nil, label: "Modifier") {
                    vm.intentionEditingByKeyboard = true
                }
            }
        }
    }

    private var editingPanel: some View {
        VStack(spacing: 12) {
            TextField("présence", text: $vm.intentionWord)
                .multilineTextAlignment(.center)
                .font(.system(size: 56, weight: .medium, design: .serif))
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

            Button {
                vm.intentionEditingByKeyboard = false
            } label: {
                Text("← Tu peux aussi reparler")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(LumenColor.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func actionStackButton(systemImage: String?, glyph: String?, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .medium))
                }
                if let glyph {
                    Text(glyph)
                        .font(.system(size: 17))
                }
                Text(label)
                    .font(.system(size: 17, weight: .medium))
            }
            .foregroundStyle(LumenColor.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                    .stroke(LumenColor.accent, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
