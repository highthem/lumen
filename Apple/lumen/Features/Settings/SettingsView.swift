import SwiftUI

struct SettingsView: View {
    @State var vm: SettingsViewModel
    @State private var exportItem: ExportItem?
    @State private var showEraseAlert = false
    @State private var showEraseRitualsAlert = false
    @State private var eraseError: String?
    @State private var exportError: String?

    /// Builds the BYOK Mode-avancé screen on demand.
    let makeAdvancedVM: () -> SettingsAdvancedViewModel

    /// Live BYOK store — drives the badge + advanced row sub-label.
    var keyStore: UserAPIKeyStore

    var body: some View {
        NavigationStack {
            Form {
                presenceSection
                voixSection
                appearanceSection
                aiSection
                ethicalSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(LumenColor.bgPrimary)
            .navigationTitle("Réglages")
            .toolbar {
                if keyStore.hasKey {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("● Clé personnelle")
                            .lumenFont(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(LumenColor.accent)
                            .padding(.horizontal, LumenSpacing.s)
                    }
                }
            }
            .task {
                await keyStore.load()
            }
            .accessibilityIdentifier("settings-screen")
            .onDisappear {
                vm.stopPreview()
            }
        }
        .sheet(item: $exportItem) { item in
            ShareSheet(activityItems: [item.url])
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
        .alert("Effacer ton historique ?", isPresented: $showEraseRitualsAlert) {
            Button("Effacer", role: .destructive) {
                Task {
                    do {
                        try await vm.eraseAllRituals()
                    } catch {
                        eraseError = error.localizedDescription
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Toutes les réponses de tes rituels passés seront supprimées définitivement. Cette action est irréversible.")
        }
        .alert("Export impossible", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    // MARK: - Sections

    private var presenceSection: some View {
        Section("Présence") {
            Picker("Durée du timer de présence", selection: $vm.presenceDurationSeconds) {
                Text("30 s").tag(30)
                Text("1 min").tag(60)
                Text("1 min 30").tag(90)
                Text("2 min").tag(120)
            }
            .accessibilityIdentifier("presence-duration-picker")

            Picker("Respiration", selection: $vm.breathingSoundId) {
                ForEach(vm.breathingSounds) { sound in
                    Text(sound.displayName).tag(sound.id)
                }
            }
        }
    }

    private var voixSection: some View {
        Section("Voix") {
            LumenToggle(isOn: $vm.voiceModeEnabled, label: "Mode vocal par défaut")
                .accessibilityIdentifier("voice-default-toggle")

            if vm.elevenLabsKeyAvailable {
                LumenToggle(isOn: $vm.elevenLabsEnabled, label: "Voix premium ElevenLabs")
                    .accessibilityIdentifier("voice-elevenlabs-toggle")

                Text("La voix premium est synthétisée par ElevenLabs. Le texte de ta synthèse y est transmis. Désactive le mode premium pour rester 100 % on-device.")
                    .lumenFont(.footnote)
                    .foregroundStyle(LumenColor.textSecondary)
            }

            Text("L'audio reste sur ton téléphone. Aucun envoi à Apple ou ailleurs.")
                .lumenFont(.footnote)
                .italic()
                .foregroundStyle(LumenColor.textTertiary)
        }
    }

    private var aiSection: some View {
        Section("IA") {
            WaterfallStatusList(steps: [
                WaterfallStatusList.Step(
                    label: "Lumen AI",
                    sublabel: keyStore.hasKey ? "Cloud · clé personnelle" : "Cloud · primaire",
                    status: .live,
                    statusLabel: "En cours"
                ),
                WaterfallStatusList.Step(
                    label: "Apple Intelligence",
                    sublabel: "On-device · iPhone 15 Pro et plus",
                    status: appleIntelligenceStatus,
                    statusLabel: appleIntelligenceLabel
                ),
                WaterfallStatusList.Step(
                    label: "File d'attente",
                    sublabel: "Si pas de réseau · génération différée",
                    status: .standby,
                    statusLabel: "Stand-by"
                )
            ])

            Text(keyStore.hasKey
                 ? "Illimité · clé personnelle active."
                 : "3 synthèses par jour · 3 questions « Ask Lumen ».")
                .lumenFont(.chipLabel)
                .fontWeight(.regular)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            #if DEBUG
            NavigationLink {
                SettingsAdvancedView(vm: makeAdvancedVM())
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: LumenSpacing.xxs) {
                        Text("Mode avancé")
                            .lumenFont(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(LumenColor.textPrimary)
                        Text(advancedSubLabel)
                            .lumenFont(.footnote)
                            .foregroundStyle(LumenColor.textSecondary)
                    }
                    Spacer()
                }
            }
            .accessibilityIdentifier("settings-advanced-link")
            #endif

            Text(keyStore.hasKey
                 ? "Lumen AI utilise ta clé personnelle. Aucune donnée ne quitte ton appareil vers nos serveurs."
                 : "Génération distante, sans stockage. Tes réponses ne traversent jamais nos serveurs.")
                .lumenFont(.footnoteSerif)
                .italic()
                .foregroundStyle(LumenColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var advancedSubLabel: String {
        guard keyStore.hasKey else { return "Utiliser ma propre clé API" }
        return "Ta clé \(keyStore.provider.displayName) · active"
    }

    private var ethicalSection: some View {
        Section("Monitoring éthique") {
            Button("Exporter en JSON") {
                Task {
                    do {
                        let url = try await vm.exportLogsFile()
                        exportItem = ExportItem(url: url)
                    } catch {
                        exportError = error.localizedDescription
                    }
                }
            }
            .foregroundStyle(LumenColor.accent)
            .accessibilityIdentifier("export-json-button")

            Button("Effacer mes logs", role: .destructive) {
                showEraseAlert = true
            }

            Button("Effacer mon historique de rituels", role: .destructive) {
                showEraseRitualsAlert = true
            }
            .accessibilityIdentifier("settings-erase-rituals-button")
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
            .accessibilityIdentifier("appearance-picker")
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
            return AppleIntelligenceProvider.isAvailable ? "Disponible" : "Indispo"
        }
        #endif
        return "Indispo"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}

// MARK: - Export item (drives the share sheet via .sheet(item:))

struct ExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - ShareSheet wrapper

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        // iPad needs a popover anchor; without it the sheet silently fails to present.
        if let popover = vc.popoverPresentationController {
            let anchor = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first
            popover.sourceView = anchor
            if let bounds = anchor?.bounds {
                popover.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
            }
            popover.permittedArrowDirections = []
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#if DEBUG
#Preview {
    let keyStore = UserAPIKeyStore()
    let openAI = OpenAIClient()
    let anthropic = AnthropicClient()
    return SettingsView(
        vm: .preview,
        makeAdvancedVM: {
            SettingsAdvancedViewModel(
                keyStore: keyStore,
                openAIClient: openAI,
                anthropicClient: anthropic
            )
        },
        keyStore: keyStore
    )
    .preferredColorScheme(.dark)
}
#endif
