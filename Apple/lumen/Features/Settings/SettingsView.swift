import SwiftUI

struct SettingsView: View {
    @State var vm: SettingsViewModel
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var showEraseAlert = false
    @State private var eraseError: String?
    @State private var showAskLumen = false

    var body: some View {
        NavigationStack {
            Form {
                rituelSection
                voiceSection
                aiSection
                ethicalSection
                appearanceSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(LumenColor.bgPrimary)
            .navigationTitle("Réglages")
            .onAppear { vm.load() }
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Effacer les logs ?", isPresented: $showEraseAlert) {
            Button("Effacer", role: .destructive) {
                Task {
                    do {
                        try await vm.eraseAllLogs()
                    } catch {
                        eraseError = error.localizedDescription
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Toutes tes données de monitoring éthique seront supprimées définitivement.")
        }
    }

    // MARK: - Sections

    private var rituelSection: some View {
        Section("Rituel") {
            HStack {
                Text("Durée du timer de présence")
                Spacer()
                Text("60 s")
                    .foregroundStyle(LumenColor.textSecondary)
            }
        }
    }

    private var voiceSection: some View {
        Section("Voix") {
            LumenToggle(isOn: $vm.voiceModeEnabled, label: "Mode vocal par défaut")

            if !vm.availableVoices.isEmpty {
                Picker("Voix", selection: $vm.selectedVoiceId) {
                    ForEach(vm.availableVoices) { voice in
                        Text("\(voice.name) (\(voice.lang.uppercased()))")
                            .tag(voice.id)
                    }
                }
            }

            LumenSegmentedControl(
                options: vm.speedOptions,
                selection: $vm.selectedSpeed,
                label: { $0.label }
            )

            Text("L'audio reste sur ton téléphone. Aucun envoi à Apple ou ailleurs.")
                .font(.system(size: 13, weight: .regular))
                .italic()
                .foregroundStyle(LumenColor.textTertiary)

            Button("Vérifier les permissions") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundStyle(LumenColor.accent)
        }
    }

    private var aiSection: some View {
        Section("Intelligence Artificielle") {
            WaterfallStatusList(steps: [
                WaterfallStatusList.Step(
                    label: "OpenAI GPT-4o-mini",
                    status: hasOpenAIKey ? .live : .warn,
                    statusLabel: hasOpenAIKey ? "Actif" : "Clé manquante"
                ),
                WaterfallStatusList.Step(
                    label: "Anthropic Claude",
                    status: hasAnthropicKey ? .live : .warn,
                    statusLabel: hasAnthropicKey ? "Actif" : "Clé manquante"
                ),
                WaterfallStatusList.Step(
                    label: "Apple Intelligence",
                    status: appleIntelligenceStatus,
                    statusLabel: appleIntelligenceLabel
                ),
                WaterfallStatusList.Step(
                    label: "File d'attente hors-ligne",
                    status: .standby,
                    statusLabel: "Secours"
                )
            ])
        }
    }

    private var ethicalSection: some View {
        Section("Monitoring éthique") {
            Button("Exporter en JSON") {
                Task {
                    do {
                        exportURL = try await vm.exportLogsFile()
                        showExportSheet = true
                    } catch {}
                }
            }
            .foregroundStyle(LumenColor.accent)

            Button("Effacer mes logs", role: .destructive) {
                showEraseAlert = true
            }
        }
    }

    private var appearanceSection: some View {
        Section("Apparence") {
            Picker("Thème", selection: $vm.appearance) {
                ForEach(AppAppearance.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var aboutSection: some View {
        Section("À propos") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(LumenColor.textSecondary)
            }
            HStack {
                Text("Build")
                Spacer()
                Text(buildNumber)
                    .foregroundStyle(LumenColor.textSecondary)
            }
            Text("Politique de confidentialité : Lumen ne collecte, ne transmet et ne vend aucune donnée personnelle.")
                .lumenFont(.footnote)
                .foregroundStyle(LumenColor.textTertiary)
        }
    }

    // MARK: - Helpers

    private var hasOpenAIKey: Bool {
        APIKeyResolver.isPresent(infoKey: "OPENAI_API_KEY")
    }

    private var hasAnthropicKey: Bool {
        APIKeyResolver.isPresent(infoKey: "ANTHROPIC_API_KEY")
    }

    private var appleIntelligenceStatus: WaterfallStatusList.Step.Status {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return AppleIntelligenceProvider.isAvailable ? .live : .standby
        }
        #endif
        return .standby
    }

    private var appleIntelligenceLabel: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return AppleIntelligenceProvider.isAvailable ? "Disponible" : "Non disponible"
        }
        #endif
        return "Non disponible"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}

// MARK: - ShareSheet wrapper

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
