import SwiftUI

struct DashboardHomeView: View {
    @State var vm: DashboardHomeViewModel
    let refreshKey: Int
    let onStartRitual: () -> Void
    let onNavigateToAlarms: () -> Void
    let onAskLumen: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LumenColor.bgPrimary.ignoresSafeArea()

            // Subtle top glow (matches `.glow-top` from the design system).
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
                        cardGrid(snapshot: nil, opacity: LumenOpacity.ring)
                    } else {
                        postHeader
                        if let intention = vm.snapshot?.intention {
                            heroIntentionCard(word: intention)
                        }
                        cardGrid(snapshot: vm.snapshot, opacity: 1.0)
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
            if let focus = vm.snapshot?.work ?? vm.snapshot?.relations {
                Text(focus)
                    .lumenFont(.chipLabel)
                    .fontWeight(.regular)
                    .lineSpacing(LumenLineSpacing.m)
                    .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.arc))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LumenSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: LumenRadius.xl, style: .continuous)
                .fill(LumenColor.bgSecondary)
        )
    }

    // MARK: - Card grid (5-cell with gratitude spanning two columns)

    private func cardGrid(snapshot: DashboardSnapshot?, opacity: Double) -> some View {
        VStack(spacing: LumenSpacing.sm2) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: LumenSpacing.sm2), GridItem(.flexible(), spacing: LumenSpacing.sm2)],
                spacing: LumenSpacing.sm2
            ) {
                DashboardCard(
                    eyebrow: DashboardCategory.energy.displayName,
                    value: snapshot?.energy,
                    footnote: nil
                ) {}.opacity(opacity)

                DashboardCard(
                    eyebrow: DashboardCategory.body.displayName,
                    value: snapshot?.bodyCheckin.hydrationNote,
                    footnote: nil
                ) {}.opacity(opacity)

                DashboardCard(
                    eyebrow: DashboardCategory.relations.displayName,
                    value: snapshot?.relations,
                    footnote: nil
                ) {}.opacity(opacity)

                DashboardCard(
                    eyebrow: DashboardCategory.work.displayName,
                    value: snapshot?.work,
                    footnote: nil
                ) {}.opacity(opacity)
            }

            // Gratitude — full width, italic serif
            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                Eyebrow(DashboardCategory.gratitude.displayName)
                Text(snapshot?.gratitude ?? "—")
                    .lumenFont(.title2)
                    .fontWeight(.regular)
                    .italic()
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LumenSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous)
                    .fill(LumenColor.bgSecondary)
            )
            .opacity(opacity)
        }
    }

    // MARK: - Ask Lumen FAB

    private var askLumenFAB: some View {
        AskLumenFAB(action: onAskLumen)
            .padding(.trailing, LumenSpacing.l)
            .padding(.bottom, LumenSpacing.l)
    }
}
