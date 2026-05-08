#if DEBUG
import SwiftUI

struct ComponentDetailView: View {
    let entry: ComponentEntry

    @State private var scheme: PreviewScheme = .both

    enum PreviewScheme: String, CaseIterable, Identifiable {
        case light, dark, both
        var id: String { rawValue }
        var label: String {
            switch self {
            case .light: return "Light"
            case .dark:  return "Dark"
            case .both:  return "Both"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Scheme", selection: $scheme) {
                ForEach(PreviewScheme.allCases) { s in Text(s.label).tag(s) }
            }
            .pickerStyle(.segmented)
            .padding(LumenSpacing.m)

            ScrollView {
                switch scheme {
                case .light:
                    pane(.light)
                case .dark:
                    pane(.dark)
                case .both:
                    VStack(spacing: 0) {
                        pane(.light)
                        Divider()
                        pane(.dark)
                    }
                }
            }
        }
        .navigationTitle(entry.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pane(_ s: ColorScheme) -> some View {
        ComponentRenderer(entry: entry)
            .padding(LumenSpacing.l)
            .frame(maxWidth: .infinity, minHeight: 240)
            .background(LumenColor.bgPrimary)
            .environment(\.colorScheme, s)
            .preferredColorScheme(s)
    }
}

private struct ComponentRenderer: View {
    let entry: ComponentEntry

    var body: some View {
        switch entry {
        case .primaryCTA:             PrimaryCTAVariants()
        case .secondaryCTA:           SecondaryCTAVariants()
        case .ghostCTA:               GhostCTAVariants()
        case .micCTA:                 MicCTAVariants()
        case .askLumenFAB:            AskLumenFABVariants()
        case .lumenToggle:            LumenToggleVariants()
        case .segmentedControl:       SegmentedControlVariants()
        case .serifUnderlineField:    SerifUnderlineFieldVariants()
        case .chromaticSlider:        ChromaticSliderVariants()
        case .wheelTimePicker:        WheelTimePickerVariants()
        case .dashboardCard:          DashboardCardVariants()
        case .cardDeck:               CardDeckVariants()
        case .footerRow:              FooterRowVariants()
        case .waterfallStatusList:    WaterfallStatusListVariants()
        case .priorityIcon:           PriorityIconVariants()
        case .eyebrow:                EyebrowVariants()
        case .sectionTitle:           SectionTitleVariants()
        case .progressDots4:          ProgressDots4Variants()
        case .appleIntelligenceBadge: AppleIntelligenceBadgeVariants()
        case .alarmSunrise:           AlarmSunriseVariants()
        case .breathingCircle:        BreathingCircleVariants()
        case .slowPulse:              SlowPulseVariants()
        case .kineticText:            KineticTextVariants()
        case .liveTranscript:         LiveTranscriptVariants()
        case .toast:                  ToastVariants()
        case .halfSheet:              HalfSheetVariants()
        case .listenPlayer:           ListenPlayerVariants()
        }
    }
}

// MARK: - Variants

private struct LabeledRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Text(label)
                .lumenFont(.caption)
                .foregroundStyle(LumenColor.textTertiary)
            content()
        }
    }
}

private struct PrimaryCTAVariants: View {
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            LabeledRow(label: "enabled") {
                PrimaryCTA("Continuer") {}
            }
            LabeledRow(label: "disabled") {
                PrimaryCTA("Continuer", isEnabled: false) {}
            }
        }
    }
}

private struct SecondaryCTAVariants: View {
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            LabeledRow(label: "enabled") {
                SecondaryCTA("Plus tard") {}
            }
            LabeledRow(label: "disabled") {
                SecondaryCTA("Plus tard", isEnabled: false) {}
            }
        }
    }
}

private struct GhostCTAVariants: View {
    var body: some View {
        GhostCTA(title: "Passer cette étape") {}
    }
}

private struct MicCTAVariants: View {
    @State private var listening = false
    var body: some View {
        VStack(spacing: LumenSpacing.xl) {
            LabeledRow(label: "tap to toggle listening") {
                MicCTA(isListening: listening, onPressDown: { listening = true }, onPressUp: { listening = false })
            }
            Text(listening ? "listening…" : "idle")
                .lumenFont(.caption)
                .foregroundStyle(LumenColor.textTertiary)
        }
    }
}

private struct AskLumenFABVariants: View {
    var body: some View { AskLumenFAB(action: {}) }
}

private struct LumenToggleVariants: View {
    @State private var on = true
    @State private var off = false
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            LumenToggle(isOn: $on, label: "Voix lente")
            LumenToggle(isOn: $off, label: "Notifications")
        }
    }
}

private struct SegOption: Hashable, Identifiable {
    let id: String
    var label: String { id }
}

private struct SegmentedControlVariants: View {
    private let options: [SegOption] = [.init(id: "Jour"), .init(id: "Semaine"), .init(id: "Mois")]
    @State private var selection: SegOption = .init(id: "Semaine")
    var body: some View {
        LumenSegmentedControl(options: options, selection: $selection, label: { $0.label })
    }
}

private struct SerifUnderlineFieldVariants: View {
    @State private var text = ""
    var body: some View {
        SerifUnderlineField(text: $text, placeholder: "ton intention…")
    }
}

private struct ChromaticSliderVariants: View {
    @State private var level = 2
    var body: some View {
        ChromaticSlider(level: $level) { ink in
            VStack {
                Text("level \(level)")
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .foregroundStyle(ink)
                Text("drag up or down")
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(ink.opacity(0.7))
            }
        }
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l))
    }
}

private struct WheelTimePickerVariants: View {
    @State private var date: Date = PreviewSamples.alarmDate
    var body: some View {
        WheelTimePicker(selection: $date)
            .frame(height: 180)
    }
}

private struct DashboardCardVariants: View {
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            DashboardCard(eyebrow: "Énergie", value: "7 / 10", footnote: "Pic à 9h", action: {})
            DashboardCard(eyebrow: "Intention", value: nil, footnote: nil, action: {})
        }
    }
}

private struct CardDeckVariants: View {
    @State private var current = 0
    @State private var selected: PriorityCategory? = nil
    var body: some View {
        CardDeck(items: PriorityCategory.allCases, current: $current, selected: $selected) { item, isSel in
            VStack(spacing: LumenSpacing.m) {
                PriorityIcon(category: item, size: 32)
                    .foregroundStyle(LumenColor.accent)
                Text(item.displayName)
                    .lumenFont(.title2)
                    .foregroundStyle(LumenColor.textPrimary)
                if isSel {
                    Text("selected")
                        .lumenFont(.caption)
                        .foregroundStyle(LumenColor.accent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(LumenSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.l)
                    .fill(LumenColor.bgSecondary)
            )
            .onTapGesture { selected = item }
        }
    }
}

private struct FooterRowVariants: View {
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            FooterRow(backTitle: "Retour", nextTitle: "Continuer", isNextEnabled: true, onBack: {}, onNext: {})
            FooterRow(backTitle: "Retour", nextTitle: "Continuer", isNextEnabled: false, onBack: {}, onNext: {})
            FooterRow(backTitle: "Retour", nextTitle: "Commencer", isNextEnabled: true, onBack: {}, onNext: {}, showBack: false)
        }
    }
}

private struct WaterfallStatusListVariants: View {
    var body: some View {
        WaterfallStatusList(steps: [
            .init(label: "Capture vocale", status: .live, statusLabel: "Live"),
            .init(label: "Transcription", sublabel: "iOS Speech", status: .live, statusLabel: "OK"),
            .init(label: "Synthèse OpenAI", status: .standby, statusLabel: "Standby"),
            .init(label: "Repli Claude", status: .warn, statusLabel: "Warn"),
        ])
    }
}

private struct PriorityIconVariants: View {
    var body: some View {
        HStack(spacing: LumenSpacing.l) {
            ForEach(PriorityCategory.allCases, id: \.self) { c in
                VStack(spacing: 4) {
                    PriorityIcon(category: c, size: 28)
                        .foregroundStyle(LumenColor.accent)
                    Text(c.rawValue).lumenFont(.caption).foregroundStyle(LumenColor.textTertiary)
                }
            }
        }
    }
}

private struct EyebrowVariants: View {
    var body: some View { Eyebrow("Section eyebrow") }
}

private struct SectionTitleVariants: View {
    var body: some View { SectionTitle("Aujourd'hui") }
}

private struct ProgressDots4Variants: View {
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            ForEach(0..<4, id: \.self) { i in
                ProgressDots4(current: i)
            }
        }
    }
}

private struct AppleIntelligenceBadgeVariants: View {
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            AppleIntelligenceBadge()
            AppleIntelligenceBadge(shimmer: true)
        }
    }
}

private struct AlarmSunriseVariants: View {
    var body: some View {
        AlarmSunrise()
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l))
    }
}

private struct BreathingCircleVariants: View {
    var body: some View { BreathingCircle() }
}

private struct SlowPulseVariants: View {
    var body: some View { SlowPulse() }
}

private struct KineticTextVariants: View {
    var body: some View {
        KineticText(PreviewSamples.intentionWords)
            .lumenFont(.title2)
            .foregroundStyle(LumenColor.textPrimary)
    }
}

private struct LiveTranscriptVariants: View {
    var body: some View {
        LiveTranscript(
            text: PreviewSamples.mediumLine,
            font: .bodySerif,
            color: LumenColor.textPrimary,
            isItalic: true
        )
    }
}

private struct ToastVariants: View {
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            Toast(message: "Synthèse prête à écouter")
            Toast(message: "Sans dot", accentDot: false)
        }
    }
}

private struct HalfSheetVariants: View {
    @State private var open = false
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            PrimaryCTA("Open sheet") { open = true }
            HalfSheet(isPresented: $open) {
                VStack(spacing: LumenSpacing.l) {
                    SectionTitle("Sheet content")
                    Text(PreviewSamples.mediumLine)
                        .lumenFont(.bodySerif)
                        .foregroundStyle(LumenColor.textPrimary)
                    PrimaryCTA("Close") { open = false }
                }
                .padding(LumenSpacing.l)
            }
        }
    }
}

private struct ListenPlayerVariants: View {
    @State private var playing = false
    @State private var progress: Double = 0.4
    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            ListenPlayer(isPlaying: playing, progress: progress, durationLabel: "38 s", elapsedLabel: "0:14") {
                playing.toggle()
            }
            Slider(value: $progress, in: 0...1)
                .tint(LumenColor.accent)
        }
    }
}

#Preview {
    NavigationStack { ComponentDetailView(entry: .primaryCTA) }
}
#endif
