import SwiftUI

struct DashboardHomeView: View {
    @State var vm: DashboardHomeViewModel
    let onStartRitual: () -> Void
    let onNavigateToAlarms: () -> Void
    let onAskLumen: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LumenColor.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topHeader

                    if !vm.hasAnyAlarm {
                        emptyState
                    } else if !vm.hasRitualToday {
                        idleState
                    } else {
                        postRitualState
                    }
                }
                .padding(.horizontal, LumenSpacing.l)
                .padding(.bottom, LumenSpacing.huge)
            }

            // FAB — Ask Lumen (only when user has done at least one ritual)
            if vm.hasRitualToday || vm.hasAnyRitual {
                Button(action: onAskLumen) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Ask Lumen")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(LumenColor.bgPrimary)
                    .padding(.horizontal, LumenSpacing.m)
                    .padding(.vertical, LumenSpacing.s + 2)
                    .background(LumenColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: LumenRadius.round, style: .continuous))
                    .shadow(color: LumenColor.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, LumenSpacing.l)
                .padding(.bottom, LumenSpacing.l)
            }
        }
        .task { await vm.load() }
    }

    // MARK: - Header

    private var topHeader: some View {
        HStack {
            Eyebrow("Lumen")
            Spacer()
            if vm.hasAnyAlarm {
                Eyebrow(formattedDate)
            }
        }
        .padding(.top, LumenSpacing.l)
        .padding(.bottom, LumenSpacing.l)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return "Aujourd'hui · \(formatter.string(from: Date()).capitalized)"
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.m) {
            Spacer(minLength: 60)

            Text("Ton premier matin t'attend.")
                .font(.system(size: 40, weight: .regular, design: .serif))
                .foregroundStyle(LumenColor.textPrimary)
                .lineSpacing(LumenFont.title1.lineSpacing)

            Text("Commence ton rituel du matin pour découvrir ta synthèse personnelle.")
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
                .padding(.bottom, LumenSpacing.xl)

            PrimaryCTA("Programmer mon réveil") {
                onNavigateToAlarms()
            }
        }
    }

    // MARK: - Idle state

    private var idleState: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            // Banner card
            VStack(alignment: .leading, spacing: LumenSpacing.m) {
                SectionTitle("Tu n'as pas encore fait ton rituel.")
                SecondaryCTA("Démarrer") {
                    onStartRitual()
                }
            }
            .padding(LumenSpacing.l)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous))

            // Grayed cards grid
            cardGrid(snapshot: nil, opacity: 0.55)
        }
    }

    // MARK: - Post-ritual state

    private var postRitualState: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.l) {
            cardGrid(snapshot: vm.snapshot, opacity: 1.0)
        }
    }

    // MARK: - Card grid

    private func cardGrid(snapshot: DashboardSnapshot?, opacity: Double) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: LumenSpacing.m
        ) {
            DashboardCard(
                eyebrow: DashboardCategory.energy.displayName,
                value: snapshot?.energy,
                footnote: nil
            ) {}
            .opacity(opacity)

            DashboardCard(
                eyebrow: DashboardCategory.intention.displayName,
                value: snapshot?.intention,
                footnote: nil
            ) {}
            .opacity(opacity)

            DashboardCard(
                eyebrow: DashboardCategory.body.displayName,
                value: snapshot?.bodyCheckin.hydrationNote,
                footnote: nil
            ) {}
            .opacity(opacity)

            DashboardCard(
                eyebrow: DashboardCategory.relations.displayName,
                value: snapshot?.relations,
                footnote: nil
            ) {}
            .opacity(opacity)

            DashboardCard(
                eyebrow: DashboardCategory.work.displayName,
                value: snapshot?.work,
                footnote: nil
            ) {}
            .opacity(opacity)

            DashboardCard(
                eyebrow: DashboardCategory.gratitude.displayName,
                value: snapshot?.gratitude,
                footnote: nil
            ) {}
            .opacity(opacity)
        }
    }
}
