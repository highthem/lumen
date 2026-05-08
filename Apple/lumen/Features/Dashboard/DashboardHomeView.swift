import SwiftUI

struct DashboardHomeView: View {
    @State var vm: DashboardHomeViewModel
    let refreshKey: Int
    let onStartRitual: () -> Void
    let onNavigateToAlarms: () -> Void
    let onAskLumen: () -> Void

    @State private var showSleepSheet: Bool = false
    @State private var selectedCategory: DashboardCategory?

    var body: some View {
        NavigationStack {
            content
                .navigationDestination(item: $selectedCategory) { category in
                    CategoryDetailView(category: category, onAskLumen: onAskLumen)
                }
        }
    }

    private var content: some View {
        ZStack(alignment: .bottomTrailing) {
            LumenColor.bgPrimary.ignoresSafeArea()

            // Subtle top glow
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [LumenColor.accent.opacity(LumenOpacity.p08), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: LumenSize.cardForm)
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(alignment: .leading, spacing: LumenSpacing.l) {
                    if !vm.hasAnyAlarm {
                        emptyState
                    } else if !vm.hasRitualToday {
                        // V11 idle: minimal hero — greeting + breathing circle
                        // + "Commencer" CTA. No banner, no dimmed cards (the
                        // 6-card grid is reserved for post-ritual recall).
                        idleHero
                    } else {
                        postHeader
                        postRitualBody
                    }
                }
                .padding(.horizontal, LumenSpacing.l)
                .padding(.top, LumenSpacing.l)
                .padding(.bottom, LumenSpacing.huge)
            }

            // Per handoff `screens.html:42-55` — Ask Lumen FAB only appears
            // on post-ritual ("ne s'affiche que sur .post"). Idle and empty
            // states stay clean to keep the morning glance uncluttered.
            if vm.hasRitualToday {
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

    // MARK: - Headers

    private var idleHeader: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow(formattedDate)
            Text("Bonjour.")
                .lumenFont(.title1)
                .foregroundStyle(LumenColor.textPrimary)
        }
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow(formattedDate)
            Text("Aujourd'hui.")
                .lumenFont(.title1)
                .foregroundStyle(LumenColor.textPrimary)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: Date()).capitalized
    }

    // MARK: - Empty state (no alarm scheduled yet)

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.m) {
            Spacer(minLength: LumenSize.blockMd)

            Eyebrow("Lumen")

            Text("Ton premier matin\nt'attend.")
                .lumenFont(.synthesisHero)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Programme une alarme.\nOn s'occupe du reste.")
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
                .padding(.bottom, LumenSpacing.xl)

            PrimaryCTA("Programmer mon réveil") {
                onNavigateToAlarms()
            }
            .accessibilityIdentifier("ritual-cta")
        }
    }

    // MARK: - Idle hero (alarm scheduled, no ritual today)

    /// V12 idle layout per `~/Downloads/lumen/project/03-mockups.html`
    /// "Dashboard · 3 états" → "Idle". Composed of the date+greeting header,
    /// the hero card (sun glyph + CTA), then (in subsequent iterations) the
    /// 7-day streak block and the "Ce matin tu vas explorer" category list.
    private var idleHero: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            idleHeader
            IdleHeroCard(onStart: onStartRitual)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Post-ritual body (V11 mixed layout, NOT 6-card grid)

    /// V11 post-ritual layout per `~/Downloads/.../NSIRD_a5XOh5/Screenshot 2026-05-08 at 18.52.28.png`:
    /// PRIORITÉ section (eyebrow + accent italic) → 2-card row (HUMEUR/ÉNERGIE)
    /// → GRATITUDE section (eyebrow + body italic) → 2-card row (PRÉSENCE/SOMMEIL).
    @ViewBuilder
    private var postRitualBody: some View {
        let s = vm.snapshot

        if let priority = s?.priority?.text, !priority.isEmpty {
            prioritySection(text: priority)
        }

        HStack(spacing: LumenSpacing.sm2) {
            moodCard(snapshot: s).frame(maxWidth: .infinity)
            energyCard(snapshot: s).frame(maxWidth: .infinity)
        }

        if let gratitude = s?.gratitude, !gratitude.isEmpty {
            gratitudeSection(text: gratitude)
        }

        HStack(spacing: LumenSpacing.sm2) {
            presenceCard(snapshot: s).frame(maxWidth: .infinity)
            sleepCard(snapshot: s).frame(maxWidth: .infinity)
        }
    }

    private func prioritySection(text: String) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow("Ta priorité")
            Text(text)
                .lumenFont(.bodySerifLg)
                .italic()
                .foregroundStyle(LumenColor.accent)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("dashboard-priority-text")
        .contentShape(Rectangle())
        .onTapGesture { selectedCategory = .priority }
    }

    private func gratitudeSection(text: String) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow("Gratitude")
            Text(text)
                .lumenFont(.bodySerif)
                .italic()
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("dashboard-gratitude-text")
        .contentShape(Rectangle())
        .onTapGesture { selectedCategory = .gratitude }
    }

    private func moodCard(snapshot: DashboardSnapshot?) -> some View {
        DashboardCard(
            eyebrow: DashboardCategory.mood.displayName,
            value: snapshot?.mood?.tag.map { $0.capitalized },
            footnote: nil
        ) { if vm.hasRitualToday { selectedCategory = .mood } }
            .accessibilityIdentifier("dashboard-card-mood")
    }

    private func energyCard(snapshot: DashboardSnapshot?) -> some View {
        DashboardCard(
            eyebrow: DashboardCategory.energy.displayName,
            value: snapshot?.energy?.displayName,
            footnote: nil
        ) { if vm.hasRitualToday { selectedCategory = .energy } }
            .accessibilityIdentifier("dashboard-card-energy")
    }

    private func presenceCard(snapshot: DashboardSnapshot?) -> some View {
        PresenceCard(state: snapshot?.presence ?? .notStarted) {
            if vm.hasRitualToday { selectedCategory = .presence }
        }
        .accessibilityIdentifier("dashboard-card-presence")
    }

    private func sleepCard(snapshot: DashboardSnapshot?) -> some View {
        SleepCard(summary: snapshot?.sleep) {
            if snapshot?.sleep == nil {
                showSleepSheet = true
            } else if vm.hasRitualToday {
                selectedCategory = .sleep
            }
        }
    }

    // MARK: - Ask Lumen FAB

    private var askLumenFAB: some View {
        AskLumenFAB(action: onAskLumen)
            .padding(.trailing, LumenSpacing.l)
            .padding(.bottom, LumenSpacing.l)
            .accessibilityIdentifier("ask-lumen-fab")
    }
}

#if DEBUG
#Preview {
    DashboardHomeView(
        vm: .preview,
        refreshKey: 0,
        onStartRitual: {},
        onNavigateToAlarms: {},
        onAskLumen: {}
    )
    .preferredColorScheme(.dark)
}
#endif
