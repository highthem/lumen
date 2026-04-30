import SwiftUI

struct SettingsAdvancedView: View {
    @State var vm: SettingsAdvancedViewModel
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                providerSection

                keyFieldSection

                actionButtons

                infoNote

                if case .saved = vm.state {
                    Button(role: .destructive) {
                        Task { await vm.clearKey() }
                    } label: {
                        Text("Supprimer ma clé")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(LumenColor.error)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(LumenColor.error.opacity(0.6), lineWidth: 1.5)
                    )
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, LumenSpacing.l)
            .padding(.top, 8)
            .padding(.bottom, LumenSpacing.xxl)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Mode avancé")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.onAppear() }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Utilise ta propre clé.")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .tracking(-0.42)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Lumen consomme ta clé directement, sans passer par nos serveurs. Plus de limite quotidienne — tu paies ton usage à OpenAI ou Anthropic.")
                .font(.system(size: 15, design: .serif))
                .italic()
                .lineSpacing(4)
                .foregroundStyle(LumenColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Provider")
            HStack(spacing: 10) {
                ForEach(UserAPIKeyStore.Provider.allCases, id: \.self) { provider in
                    providerChip(provider)
                }
            }
        }
    }

    private func providerChip(_ provider: UserAPIKeyStore.Provider) -> some View {
        let selected = vm.provider == provider
        return Button {
            Task { await vm.selectProvider(provider) }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .stroke(LumenColor.accent.opacity(selected ? 0 : 0.5), lineWidth: 1.5)
                    .background(
                        Circle()
                            .fill(selected ? LumenColor.accent : .clear)
                    )
                    .frame(width: 14, height: 14)
                Text(provider.displayName)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(selected ? LumenColor.textPrimary : LumenColor.textSecondary)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? LumenColor.bgSecondary : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? LumenColor.accent.opacity(0.6) : LumenColor.divider, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var keyFieldSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Clé API")

            HStack(spacing: 10) {
                Image(systemName: "lock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LumenColor.textTertiary)

                TextField(
                    vm.provider.placeholder,
                    text: Binding(
                        get: { vm.keyDraft },
                        set: { vm.onKeyChanged($0) }
                    )
                )
                .focused($fieldFocused)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(LumenColor.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)

                trailingActionButton
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LumenColor.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )

            if case .empty = vm.state {
                Button {
                    vm.pasteFromClipboard()
                } label: {
                    Text("Coller depuis le presse-papier")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LumenColor.accent)
                }
                .buttonStyle(.plain)
            }

            statusMessage
        }
    }

    @ViewBuilder
    private var trailingActionButton: some View {
        switch vm.state {
        case .empty:
            Button("Coller") { vm.pasteFromClipboard() }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LumenColor.accent)
        case .saved:
            Button("Modifier") {
                vm.keyDraft = ""
                vm.state = .empty
                fieldFocused = true
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(LumenColor.accent)
        case .editing, .invalid, .valid:
            Button("Effacer") {
                vm.keyDraft = ""
                vm.state = .empty
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(LumenColor.textSecondary)
        case .testing:
            ProgressView().tint(LumenColor.accent)
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch vm.state {
        case .invalid(let message):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 12))
                Text(message)
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(LumenColor.error)
        case .valid:
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                Text("Clé acceptée. Enregistre-la pour activer.")
                    .font(.system(size: 13))
            }
            .foregroundStyle(LumenColor.success)
        case .saved:
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                Text("Clé valide jusqu'à révocation.")
                    .font(.system(size: 13))
            }
            .foregroundStyle(LumenColor.success)
        default:
            EmptyView()
        }
    }

    private var actionButtons: some View {
        Group {
            if case .saved = vm.state {
                EmptyView()
            } else {
                HStack(spacing: 10) {
                    SecondaryCTA("Tester la clé", isEnabled: vm.canTest) {
                        Task { await vm.testKey() }
                    }
                    PrimaryCTA("Enregistrer", isEnabled: vm.canSave) {
                        Task { await vm.save() }
                    }
                }
            }
        }
    }

    private var infoNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .font(.system(size: 14))
                .foregroundStyle(LumenColor.textSecondary.opacity(0.7))
            Text("Ta clé est stockée dans le Trousseau iOS. Aucune copie n'est envoyée hors de ton téléphone.")
                .font(.system(size: 13, design: .serif))
                .italic()
                .lineSpacing(3)
                .foregroundStyle(LumenColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LumenColor.accent.opacity(0.06))
        )
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .regular))
            .tracking(2.4)
            .textCase(.uppercase)
            .foregroundStyle(LumenColor.textTertiary)
    }

    private var borderColor: Color {
        switch vm.state {
        case .invalid: LumenColor.error.opacity(0.6)
        case .valid, .saved: LumenColor.success.opacity(0.5)
        default: LumenColor.divider
        }
    }
}
