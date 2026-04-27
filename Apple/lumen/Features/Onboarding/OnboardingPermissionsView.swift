import SwiftUI

struct OnboardingPermissionsView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { vm.goBack() }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(LumenColor.textPrimary)
                        .font(.system(size: 17, weight: .medium))
                }
                Spacer()
                ProgressDots4(current: 2)
                Spacer()
            }
            .padding(.top, LumenSpacing.xl)

            Spacer().frame(height: LumenSpacing.xl)

            Text("03 / 04")
                .font(.system(size: 11, weight: .regular))
                .tracking(11 * 0.22)
                .textCase(.uppercase)
                .foregroundStyle(LumenColor.textSecondary)

            Spacer().frame(height: LumenSpacing.m)

            Text("On a besoin de deux choses.")
                .font(.system(size: 30, weight: .semibold, design: .serif))
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
                .font(.system(size: 15, weight: .regular, design: .serif))
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
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: LumenRadius.s, style: .continuous)
                .fill(LumenColor.bgTertiary)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(LumenColor.textPrimary)
                        .font(.system(size: 18))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LumenColor.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(LumenColor.textSecondary)
            }

            Spacer()

            chip()
        }
        .padding(18)
        .background(LumenColor.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.l, style: .continuous))
    }

    private func chipLabel(_ label: String, isSelected: Bool) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isSelected ? LumenColor.bgPrimary : LumenColor.accent)
            .padding(.horizontal, LumenSpacing.m)
            .padding(.vertical, LumenSpacing.xs)
            .background(isSelected ? LumenColor.accent : LumenColor.accentMuted)
            .clipShape(Capsule())
    }
}
