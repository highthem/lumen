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
        VStack(alignment: .leading, spacing: 22) {
            ProgressDots4(current: 2)

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("03 / 04 · Gratitude")
                Text("Une gratitude ?")
                    .font(.system(size: 30, weight: .medium, design: .serif))
                    .tracking(-0.45)
                    .foregroundStyle(LumenColor.textPrimary)
            }

            VStack(spacing: 28) {
                Spacer(minLength: 0)
                centerStage
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

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

    @ViewBuilder
    private var centerStage: some View {
        if state == .editing {
            editingPanel
        } else if state == .transcribed {
            transcribedPanel
        } else {
            // default + listening share a persistent MicCTA so hold-to-talk
            // gesture state survives the state transition mid-press.
            VStack(spacing: 14) {
                MicCTA(
                    isListening: state == .listening,
                    onPressDown: { vm.startDictation(for: .gratitude) },
                    onPressUp: { Task { await vm.stopDictation(for: .gratitude) } }
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
                vm.editingByKeyboard = true
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

            if !vm.gratitudeText.isEmpty {
                LiveTranscript(
                    text: vm.gratitudeText,
                    font: .system(size: 24, weight: .medium, design: .serif),
                    color: LumenColor.accent,
                    isItalic: false,
                    charDelay: .milliseconds(38)
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, LumenSpacing.l)
            }
        }
    }

    private var transcribedPanel: some View {
        VStack(spacing: 28) {
            Text(vm.gratitudeText)
                .font(.system(size: 28, weight: .medium, design: .serif))
                .tracking(-0.14)
                .lineSpacing(2)
                .foregroundStyle(LumenColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LumenSpacing.l)
                .frame(maxWidth: 320)

            VStack(spacing: 10) {
                actionStackButton(systemImage: nil, glyph: "↺", label: "Refaire") {
                    vm.resetGratitude()
                }
                actionStackButton(systemImage: "keyboard", glyph: nil, label: "Modifier") {
                    vm.editingByKeyboard = true
                }
            }
        }
    }

    private var editingPanel: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                if vm.gratitudeText.isEmpty {
                    Text("Le silence avant que les enfants se lèvent.")
                        .font(.system(size: 19, design: .serif))
                        .foregroundStyle(LumenColor.textTertiary)
                        .padding(.top, 18)
                        .padding(.leading, 20)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $vm.gratitudeText)
                    .font(.system(size: 19, design: .serif))
                    .foregroundStyle(LumenColor.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(minHeight: 90)
                    .scrollContentBackground(.hidden)
                    .background(LumenColor.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(LumenColor.accent, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                vm.editingByKeyboard = false
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
