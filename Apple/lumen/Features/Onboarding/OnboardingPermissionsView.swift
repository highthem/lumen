import SwiftUI

struct OnboardingPermissionsView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { vm.goBack() }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(LumenColor.textPrimary)
                        .font(LumenIconFont.xxl)
                }
                Spacer()
                ProgressDots4(current: 2)
                Spacer()
            }
            .padding(.top, LumenSpacing.xl)

            Spacer().frame(height: LumenSpacing.xl)

            Text("03 / 04")
                .lumenFont(.caption)
                .textCase(.uppercase)
                .foregroundStyle(LumenColor.textSecondary)

            Spacer().frame(height: LumenSpacing.m)

            Text("On a besoin de deux choses.")
                .lumenFont(.title1)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: LumenSpacing.xl)

            VStack(spacing: LumenSpacing.m) {
                permissionCard(
                    icon: "bell.badge",
                    title: "Te notifier à l'heure choisie",
                    subtitle: "Notifications",
                    chip: {
                        AnyView(notificationChip)
                    }
                )
                permissionCard(
                    icon: "speaker.wave.2",
                    title: "Jouer un son doux",
                    subtitle: "Audio en arrière-plan",
                    chip: {
                        AnyView(
                            chipLabel("OK", isSelected: true)
                        )
                    }
                )
            }

            Spacer().frame(height: LumenSpacing.l)

            Text("On ne t'envoie rien d'autre. Promis.")
                .lumenFont(.calloutSerif)
                .italic()
                .foregroundStyle(LumenColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            PrimaryCTA("Continuer") { vm.advance() }
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.bottom, LumenSpacing.xl)
    }

    @ViewBuilder
    private var notificationChip: some View {
        if vm.notificationsAuthorized {
            chipLabel("Activé", isSelected: true)
        } else {
            Button {
                Task { await vm.requestNotificationAuthorization() }
            } label: {
                chipLabel("Activer", isSelected: false)
            }
        }
    }

    private func permissionCard(icon: String, title: String, subtitle: String, chip: () -> AnyView) -> some View {
        HStack(spacing: LumenSpacing.m) {
            RoundedRectangle(cornerRadius: LumenRadius.s, style: .continuous)
                .fill(LumenColor.bgTertiary)
                .frame(width: LumenSize.iconXl, height: LumenSize.iconXl)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(LumenColor.textPrimary)
                        .font(LumenIconFont.xxxl)
                }

            VStack(alignment: .leading, spacing: LumenSpacing.xxs) {
                Text(title)
                    .lumenFont(.chipLabel)
                    .foregroundStyle(LumenColor.textPrimary)
                Text(subtitle)
                    .lumenFont(.footnote)
                    .foregroundStyle(LumenColor.textSecondary)
            }

            Spacer()

            chip()
        }
        .padding(LumenSpacing.l)
        .background(LumenColor.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous))
    }

    private func chipLabel(_ label: String, isSelected: Bool) -> some View {
        Text(label)
            .lumenFont(.footnote)
            .fontWeight(.medium)
            .foregroundStyle(isSelected ? LumenColor.bgPrimary : LumenColor.accent)
            .padding(.horizontal, LumenSpacing.m)
            .padding(.vertical, LumenSpacing.xs)
            .background(isSelected ? LumenColor.accent : LumenColor.accentMuted)
            .clipShape(Capsule())
    }
}
