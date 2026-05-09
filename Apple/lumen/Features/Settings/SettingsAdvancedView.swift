import SwiftUI

struct SettingsAdvancedView: View {
    @State var vm: SettingsAdvancedViewModel
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenSpacing.l) {
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
                            .lumenFont(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, minHeight: LumenSize.fab)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(LumenColor.error)
                    .background(
                        RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                            .stroke(LumenColor.error.opacity(LumenOpacity.p60), lineWidth: LumenSize.strokeMd)
                    )
                    .padding(.top, LumenSpacing.s)
                }
            }
            .padding(.horizontal, LumenSpacing.l)
            .padding(.top, LumenSpacing.s)
            .padding(.bottom, LumenSpacing.xxl)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Mode avancé")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.onAppear() }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.sm) {
            Text("Utilise ta propre clé.")
                .lumenFont(.title2)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Lumen consomme ta clé directement, sans passer par nos serveurs. Plus de limite quotidienne, tu paies ton usage à OpenAI ou Anthropic.")
                .lumenFont(.calloutSerif)
                .italic()
                .foregroundStyle(LumenColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, LumenSpacing.s)
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.sm) {
            fieldLabel("Provider")
            HStack(spacing: LumenSpacing.sm) {
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
            HStack(spacing: LumenSpacing.s) {
                Circle()
                    .stroke(LumenColor.accent.opacity(selected ? 0 : LumenOpacity.dim), lineWidth: LumenSize.strokeMd)
                    .background(
                        Circle()
                            .fill(selected ? LumenColor.accent : .clear)
                    )
                    .frame(width: LumenSize.iconSm, height: LumenSize.iconSm)
                Text(provider.displayName)
                    .lumenFont(.callout)
                    .fontWeight(.medium)
            }
            .foregroundStyle(selected ? LumenColor.textPrimary : LumenColor.textSecondary)
            .padding(.horizontal, LumenSpacing.sm3)
            .frame(height: LumenSize.buttonSm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                    .fill(selected ? LumenColor.bgSecondary : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                            .stroke(selected ? LumenColor.accent.opacity(LumenOpacity.p60) : LumenColor.divider, lineWidth: LumenSize.hairline)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("provider-\(provider.rawValue)")
    }

    private var keyFieldSection: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.sm) {
            fieldLabel("Clé API")

            HStack(spacing: LumenSpacing.sm) {
                Image(systemName: "lock")
                    .font(LumenIconFont.mdMedium)
                    .foregroundStyle(LumenColor.textTertiary)

                TextField(
                    vm.provider.placeholder,
                    text: Binding(
                        get: { vm.keyDraft },
                        set: { vm.onKeyChanged($0) }
                    )
                )
                .focused($fieldFocused)
                .font(LumenIconFont.monoSm)
                .foregroundStyle(LumenColor.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .accessibilityIdentifier("api-key-input")

                trailingActionButton
            }
            .padding(.horizontal, LumenSpacing.sm3)
            .frame(height: LumenSize.fab)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                    .fill(LumenColor.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                            .stroke(borderColor, lineWidth: LumenSize.hairline)
                    )
            )

            if case .empty = vm.state {
                Button {
                    vm.pasteFromClipboard()
                } label: {
                    Text("Coller depuis le presse-papier")
                        .lumenFont(.footnote)
                        .fontWeight(.medium)
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
                .lumenFont(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(LumenColor.accent)
        case .saved:
            Button("Modifier") {
                vm.keyDraft = ""
                vm.state = .empty
                fieldFocused = true
            }
            .lumenFont(.footnote)
            .fontWeight(.medium)
            .foregroundStyle(LumenColor.accent)
        case .editing, .invalid, .valid:
            Button("Effacer") {
                vm.keyDraft = ""
                vm.state = .empty
            }
            .lumenFont(.footnote)
            .fontWeight(.medium)
            .foregroundStyle(LumenColor.textSecondary)
        case .testing:
            ProgressView().tint(LumenColor.accent)
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch vm.state {
        case .invalid(let message):
            HStack(spacing: LumenSpacing.xs2) {
                Image(systemName: "exclamationmark.circle")
                    .font(LumenIconFont.sm)
                Text(message)
                    .lumenFont(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(LumenColor.error)
        case .valid:
            HStack(spacing: LumenSpacing.xs2) {
                Image(systemName: "checkmark")
                    .font(LumenIconFont.smSemibold)
                Text("Clé acceptée. Enregistre-la pour activer.")
                    .lumenFont(.footnote)
            }
            .foregroundStyle(LumenColor.success)
        case .saved:
            HStack(spacing: LumenSpacing.xs2) {
                Image(systemName: "checkmark")
                    .font(LumenIconFont.smSemibold)
                Text("Clé valide jusqu'à révocation.")
                    .lumenFont(.footnote)
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
                HStack(spacing: LumenSpacing.sm) {
                    SecondaryCTA("Tester la clé", isEnabled: vm.canTest) {
                        Task { await vm.testKey() }
                    }
                    .accessibilityIdentifier("test-key-button")
                    PrimaryCTA("Enregistrer", isEnabled: vm.canSave) {
                        Task { await vm.save() }
                    }
                    .accessibilityIdentifier(vm.canSave ? "save-key-button" : "save-button-disabled")
                }
            }
        }
    }

    private var infoNote: some View {
        HStack(alignment: .top, spacing: LumenSpacing.sm) {
            Image(systemName: "lock.shield")
                .font(LumenIconFont.lg)
                .foregroundStyle(LumenColor.textSecondary.opacity(LumenOpacity.p70))
            Text("Ta clé est stockée dans le Trousseau iOS. Aucune copie n'est envoyée hors de ton téléphone.")
                .lumenFont(.footnoteSerif)
                .italic()
                .lineSpacing(LumenLineSpacing.s)
                .foregroundStyle(LumenColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(LumenSpacing.sm3)
        .background(
            RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                .fill(LumenColor.accent.opacity(LumenOpacity.p06))
        )
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .lumenFont(.caption)
            .textCase(.uppercase)
            .foregroundStyle(LumenColor.textTertiary)
    }

    private var borderColor: Color {
        switch vm.state {
        case .invalid: LumenColor.error.opacity(LumenOpacity.p60)
        case .valid, .saved: LumenColor.success.opacity(LumenOpacity.dim)
        default: LumenColor.divider
        }
    }
}
