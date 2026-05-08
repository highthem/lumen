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
                        idleHeader
                        idleBanner
                        cardGrid(opacity: LumenOpacity.ring)
                    } else {
                        postHeader
                        if let intention = vm.snapshot?.aiIntention {
                            heroIntentionCard(word: intention)
                        }
                        cardGrid(opacity: 1.0)
                    }
                }
                .padding(.horizontal, LumenSpacing.l)
                .padding(.top, LumenSpacing.l)
                .padding(.bottom, LumenSpacing.huge)
            }

            if vm.hasRitualToday || vm.hasAnyRitual {
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

    // MARK: - Idle banner

    private var idleBanner: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Text("Tu n'as pas encore\nfait ton rituel.")
                .lumenFont(.title2)
                .fontWeight(.medium)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("5 minutes pour démarrer.")
                .lumenFont(.chipLabel)
                .fontWeight(.regular)
                .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.p70))

            PrimaryCTA("Démarrer") {
                onStartRitual()
            }
            .accessibilityIdentifier("ritual-cta")
            .padding(.top, LumenSpacing.s)
        }
        .padding(LumenSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: LumenRadius.xl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [LumenColor.accent.opacity(LumenOpacity.surfaceFill), LumenColor.accent.opacity(LumenOpacity.p04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LumenRadius.xl, style: .continuous)
                        .stroke(LumenColor.divider, lineWidth: LumenSize.hairline)
                )
        )
    }

    // MARK: - Hero Intention card (post-ritual)

    private func heroIntentionCard(word: String) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.sm2) {
            Eyebrow("Intention")
            Text(word)
                .lumenFont(.synthesisHero)
                .italic()
                .foregroundStyle(LumenColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LumenSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: LumenRadius.xl, style: .continuous)
                .fill(LumenColor.bgSecondary)
        )
    }

    // MARK: - Card grid (2 × 3 V2)

    private func cardGrid(opacity: Double) -> some View {
        let snapshot = vm.snapshot
        let canNavigate = vm.hasRitualToday
        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: LumenSpacing.sm2),
                GridItem(.flexible(), spacing: LumenSpacing.sm2)
            ],
            spacing: LumenSpacing.sm2
        ) {
            DashboardCard(
                eyebrow: DashboardCategory.mood.displayName,
                value: snapshot?.mood?.tag.map { $0.capitalized },
                footnote: nil
            ) { if canNavigate { selectedCategory = .mood } }
                .opacity(opacity)
                .accessibilityIdentifier("dashboard-card-mood")

            DashboardCard(
                eyebrow: DashboardCategory.energy.displayName,
                value: snapshot?.energy?.displayName,
                footnote: nil
            ) { if canNavigate { selectedCategory = .energy } }
                .opacity(opacity)
                .accessibilityIdentifier("dashboard-card-energy")

            DashboardCard(
                eyebrow: DashboardCategory.priority.displayName,
                value: snapshot?.priority?.category.displayName,
                footnote: snapshot?.priority?.note
            ) { if canNavigate { selectedCategory = .priority } }
                .opacity(opacity)
                .accessibilityIdentifier("dashboard-card-priority")

            DashboardCard(
                eyebrow: DashboardCategory.gratitude.displayName,
                value: snapshot?.gratitude,
                footnote: nil
            ) { if canNavigate { selectedCategory = .gratitude } }
                .opacity(opacity)
                .accessibilityIdentifier("dashboard-card-gratitude")

            PresenceCard(state: snapshot?.presence ?? .notStarted) {
                if canNavigate { selectedCategory = .presence }
            }
            .opacity(opacity)
            .accessibilityIdentifier("dashboard-card-presence")

            SleepCard(summary: snapshot?.sleep) {
                if snapshot?.sleep == nil {
                    showSleepSheet = true
                } else if canNavigate {
                    selectedCategory = .sleep
                }
            }
            .opacity(opacity)
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
