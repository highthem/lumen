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
                    colors: [LumenColor.accent.opacity(0.08), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 280)
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
                        cardGrid(snapshot: nil, opacity: 0.55)
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
    }

    // MARK: - Headers

    private var idleHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(formattedDate)
            Text("Bonjour.")
                .font(.system(size: 32, weight: .medium, design: .serif))
                .tracking(-0.32)
                .foregroundStyle(LumenColor.textPrimary)
        }
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(formattedDate)
            Text("Aujourd'hui.")
                .font(.system(size: 32, weight: .medium, design: .serif))
                .tracking(-0.32)
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
            Spacer(minLength: 60)

            Eyebrow("Lumen")

            Text("Ton premier matin\nt'attend.")
                .font(.system(size: 40, weight: .medium, design: .serif))
                .tracking(-0.6)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Programme une alarme.\nOn s'occupe du reste.")
                .font(.system(size: 17))
                .foregroundStyle(LumenColor.textSecondary)
                .padding(.bottom, LumenSpacing.xl)

            PrimaryCTA("Programmer mon réveil") {
                onNavigateToAlarms()
            }
        }
    }

    // MARK: - Idle banner

    private var idleBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tu n'as pas encore\nfait ton rituel.")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .tracking(-0.11)
                .lineSpacing(4)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("5 minutes pour démarrer.")
                .font(.system(size: 14))
                .foregroundStyle(LumenColor.textPrimary.opacity(0.7))

            PrimaryCTA("Démarrer") {
                onStartRitual()
            }
            .padding(.top, 8)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [LumenColor.accent.opacity(0.12), LumenColor.accent.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(LumenColor.divider, lineWidth: 1)
                )
        )
    }

    // MARK: - Hero Intention card (post-ritual)

    private func heroIntentionCard(word: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Intention")
            Text(word)
                .font(.system(size: 36, weight: .medium, design: .serif))
                .italic()
                .tracking(-0.72)
                .foregroundStyle(LumenColor.accent)
            if let focus = vm.snapshot?.work ?? vm.snapshot?.relations {
                Text(focus)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .foregroundStyle(LumenColor.textPrimary.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LumenColor.bgSecondary)
        )
    }

    // MARK: - Card grid (5-cell with gratitude spanning two columns)

    private func cardGrid(snapshot: DashboardSnapshot?, opacity: Double) -> some View {
        VStack(spacing: 12) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
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
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(DashboardCategory.gratitude.displayName)
                Text(snapshot?.gratitude ?? "—")
                    .font(.system(size: 22, design: .serif))
                    .italic()
                    .lineSpacing(2)
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous)
                    .fill(LumenColor.bgSecondary)
            )
            .opacity(opacity)
        }
    }

    // MARK: - Ask Lumen FAB

    private var askLumenFAB: some View {
        Button(action: onAskLumen) {
            Text("?")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(LumenColor.bgPrimary)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(LumenColor.accent)
                )
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
        }
        .padding(.trailing, LumenSpacing.l)
        .padding(.bottom, LumenSpacing.l)
    }
}
