import SwiftUI

struct SleepPermissionSheet: View {
    let sleepService: any SleepHealthProviding
    let onAuthorized: () -> Void
    @Binding var isPresented: Bool

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: LumenSpacing.l) {
            Image(systemName: "heart.fill")
                .font(.system(size: LumenSize.heroIcon))
                .foregroundStyle(LumenColor.accent)
                .padding(.top, LumenSpacing.l)

            Text("Lire ton sommeil ?")
                .lumenFont(.title2)
                .foregroundStyle(LumenColor.textPrimary)

            Text("Lumen lit tes données de sommeil depuis Apple Santé pour enrichir ta synthèse matinale. Tes données restent sur ton téléphone — Lumen ne les transmet à personne.")
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LumenSpacing.m)

            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                bullet("Lecture seule")
                bullet("Aucun envoi vers nos serveurs")
                bullet("Tu peux retirer l'accès dans Réglages iOS à tout moment")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LumenSpacing.l)

            Spacer(minLength: 0)

            VStack(spacing: LumenSpacing.s) {
                PrimaryCTA("Autoriser Apple Santé", isEnabled: !isRequesting) {
                    Task {
                        isRequesting = true
                        let granted = await sleepService.requestAuthorization()
                        isRequesting = false
                        if granted {
                            onAuthorized()
                        }
                        isPresented = false
                    }
                }
                .accessibilityIdentifier("sleep-permission-allow")

                Button("Plus tard") {
                    isPresented = false
                }
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
                .padding(.bottom, LumenSpacing.s)
                .accessibilityIdentifier("sleep-permission-later")
            }
            .padding(.horizontal, LumenSpacing.l)
        }
        .padding(.vertical, LumenSpacing.l)
        .frame(maxWidth: .infinity)
        .background(LumenColor.bgSecondary)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: LumenSpacing.s) {
            Circle()
                .fill(LumenColor.accent)
                .frame(width: LumenSize.dotMd, height: LumenSize.dotMd)
                .padding(.top, LumenSpacing.s)
            Text(text)
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textPrimary)
        }
    }
}
