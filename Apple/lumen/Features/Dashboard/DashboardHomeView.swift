import SwiftUI

/// Dashboard home — three mutually-exclusive states (empty / idle / post-rituel)
/// rendered to match `Design/designs/screens/screens-shell.jsx:151–553`.
/// All numeric values (paddings, radii, font sizes, colors) mirror the JSX
/// verbatim and are intentionally NOT routed through the design-system
/// spacing/typography enums where the JSX uses one-off values.
struct DashboardHomeView: View {
    @State var vm: DashboardHomeViewModel
    let refreshKey: Int
    let onStartRitual: () -> Void
    let onNavigateToAlarms: () -> Void
    let onAskLumen: () -> Void
    var onResumeRitual: ((UUID, QuestionnaireStep) -> Void)?

    @State private var showSleepSheet: Bool = false
    @State private var selectedCategory: DashboardCategory?

    var body: some View {
        NavigationStack {
            content
                .navigationDestination(item: $selectedCategory) { category in
                    CategoryDetailView(
                        category: category,
                        insight: vm.snapshot?.insights?[category],
                        onAskLumen: onAskLumen
                    )
                }
        }
    }

    private var content: some View {
        ZStack(alignment: .bottomTrailing) {
            LumenColor.bgPrimary.ignoresSafeArea()
            glowTopBackground

            ScrollView {
                Group {
                    switch vm.displayState {
                    case .empty:      emptyContent
                    case .idle:       idleContent
                    case .postRitual: postRitualContent
                    }
                }
                .padding(.horizontal, LumenSpacing.l)
                .padding(.top, LumenSpacing.m)
                .padding(.bottom, vm.displayState == .postRitual ? 90 : LumenSpacing.huge)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)

            if vm.displayState == .postRitual {
                askLumenFAB
            }
        }
        .task(id: refreshKey) { await vm.load() }
        .sheet(isPresented: $showSleepSheet) {
            SleepPermissionSheet(
                sleepService: vm.sleepService,
                onAuthorized: {
                    Task { await vm.load() }
                },
                isPresented: $showSleepSheet
            )
        }
        .accessibilityIdentifier("dashboard-screen")
    }

    // MARK: - Glow-top background gradient

    private var glowTopBackground: some View {
        VStack(spacing: 0) {
            RadialGradient(
                colors: [LumenColor.accent.opacity(0.10), Color.clear],
                center: UnitPoint(x: 0.5, y: -0.10),
                startRadius: 0,
                endRadius: 320
            )
            .frame(height: 280)
            Spacer()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Headers

    private var idleHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(formattedHeaderDate)
            Text("Bonjour.")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .italic()
                .tracking(-0.012 * 36)
                .foregroundStyle(LumenColor.textPrimary)
        }
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(formattedHeaderDate)
            Text("Aujourd'hui.")
                .font(.system(size: 32, weight: .medium, design: .serif))
                .italic()
                .tracking(-0.01 * 32)
                .foregroundStyle(LumenColor.textPrimary)
        }
    }

    /// "Vendredi 8 mai · 6 h 47" — uppercase first letter, lowercase month,
    /// "H h mm" with French spacing.
    private var formattedHeaderDate: String {
        let day = DateFormatter()
        day.locale = Locale(identifier: "fr_FR")
        day.dateFormat = "EEEE d MMMM"
        let dayString = day.string(from: Date()).capitalized

        let time = DateFormatter()
        time.locale = Locale(identifier: "fr_FR")
        time.dateFormat = "H 'h' mm"
        return "\(dayString) · \(time.string(from: Date()))"
    }

    // MARK: - Empty state

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.m) {
            Eyebrow("Lumen")

            Spacer().frame(height: 0)

            Text("Ton premier matin\nt'attend.")
                .font(.system(size: 40, weight: .medium, design: .serif))
                .italic()
                .tracking(-0.015 * 40)
                .lineSpacing(40 * 0.10)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)

            Text("Programme une alarme.\nOn s'occupe du reste.")
                .font(.system(size: 15))
                .foregroundStyle(LumenColor.textSecondary)
                .padding(.top, 4)
                .padding(.bottom, LumenSpacing.xl)

            Spacer()

            PrimaryCTA("Programmer mon réveil") {
                onNavigateToAlarms()
            }
            .accessibilityIdentifier("ritual-cta")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Idle state

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            idleHeader
            if let partial = vm.partialRitual,
               let nextStep = partial.nextQuestionnaireStep {
                resumeRitualBanner(ritual: partial, nextStep: nextStep)
            }
            IdleHeroCard(onStart: onStartRitual)
            StreakStrip(history: vm.weekHistory)
            previewChipsRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Resume ritual banner

    private func resumeRitualBanner(ritual: Ritual, nextStep: QuestionnaireStep) -> some View {
        HStack(spacing: LumenSpacing.m) {
            VStack(alignment: .leading, spacing: LumenSpacing.xs2) {
                Text("Reprendre ton rituel")
                    .lumenFont(.callout)
                    .foregroundStyle(LumenColor.textPrimary)
                Text("Tu en étais à la question \(nextStep.displayIndex)/4")
                    .lumenFont(.footnote)
                    .foregroundStyle(LumenColor.textSecondary)
            }
            Spacer(minLength: 0)
            Button {
                onResumeRitual?(ritual.id, nextStep)
            } label: {
                Text("Reprendre")
                    .lumenFont(.callout)
                    .foregroundStyle(LumenColor.accent)
                    .padding(.horizontal, LumenSpacing.m)
                    .padding(.vertical, LumenSpacing.s)
                    .background(LumenColor.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(LumenSpacing.m)
        .background(LumenColor.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous))
        .accessibilityIdentifier("resume-ritual-banner")
    }

    private var previewChipsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ce matin tu vas explorer")
                .font(.system(size: 11))
                .tracking(0.08 * 11)
                .textCase(.uppercase)
                .foregroundStyle(LumenColor.textTertiary)
                .padding(.leading, 4)

            // Wrap-friendly horizontal flow: SwiftUI's HStack wraps via
            // FlexibleHStack-style layout; but the 4 chips fit on one line
            // on iPhone 16 width — we keep it as HStack with .lineLimit
            // and rely on the layout to grow; if needed switch to a two-row
            // VStack for narrow screens.
            HStack(spacing: 8) {
                PreviewChip(index: 1, label: "Humeur")
                PreviewChip(index: 2, label: "Énergie")
                PreviewChip(index: 3, label: "Priorité")
                PreviewChip(index: 4, label: "Gratitude")
            }
        }
    }

    // MARK: - Post-rituel bento

    @ViewBuilder
    private var postRitualContent: some View {
        let s = vm.snapshot
        VStack(alignment: .leading, spacing: 14) {
            postHeader

            if let priority = s?.priority?.text, !priority.isEmpty {
                PriorityHeroCard(text: priority, insight: s?.insights?[.priority]) {
                    selectedCategory = .priority
                }
            }

            HStack(spacing: 10) {
                MoodCard(mood: s?.mood, insight: s?.insights?[.mood]) {
                    if vm.hasRitualToday { selectedCategory = .mood }
                }
                EnergyCard(energy: s?.energy, insight: s?.insights?[.energy]) {
                    if vm.hasRitualToday { selectedCategory = .energy }
                }
            }

            if let gratitude = s?.gratitude, !gratitude.isEmpty {
                GratitudeQuoteCard(text: gratitude, insight: s?.insights?[.gratitude]) {
                    selectedCategory = .gratitude
                }
            }

            HStack(spacing: 10) {
                PresenceCard(state: s?.presence ?? .notStarted, insight: s?.insights?[.presence]) {
                    if vm.hasRitualToday { selectedCategory = .presence }
                }
                SleepCard(summary: s?.sleep, insight: s?.insights?[.sleep]) {
                    if s?.sleep == nil {
                        showSleepSheet = true
                    } else if vm.hasRitualToday {
                        selectedCategory = .sleep
                    }
                }
            }

            StreakFooter(
                consecutiveStreak: vm.weekHistory.consecutiveStreak,
                nextAlarmLabel: vm.nextAlarmLabel
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - FAB

    private var askLumenFAB: some View {
        AskLumenFAB(action: onAskLumen)
            .padding(.trailing, LumenSpacing.m)
            .padding(.bottom, 30)
            .accessibilityIdentifier("ask-lumen-fab")
    }
}

#if DEBUG
#Preview("Post-rituel") {
    DashboardHomeView(
        vm: .preview,
        refreshKey: 0,
        onStartRitual: {},
        onNavigateToAlarms: {},
        onAskLumen: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Idle") {
    DashboardHomeView(
        vm: .previewIdle,
        refreshKey: 0,
        onStartRitual: {},
        onNavigateToAlarms: {},
        onAskLumen: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    DashboardHomeView(
        vm: .previewEmpty,
        refreshKey: 0,
        onStartRitual: {},
        onNavigateToAlarms: {},
        onAskLumen: {}
    )
    .preferredColorScheme(.dark)
}
#endif
