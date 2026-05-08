import SwiftUI

struct OnboardingFirstAlarmView: View {
    @Bindable var vm: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.xl) {
            HStack {
                Button(action: { vm.goBack() }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(LumenColor.textPrimary)
                        .font(LumenIconFont.xxl)
                }
                Spacer()
                ProgressDots4(current: 3)
                Spacer()
            }
            .padding(.top, LumenSpacing.xl)

            VStack(alignment: .leading, spacing: LumenSpacing.m) {
                Text("04 / 04")
                    .lumenFont(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(LumenColor.textSecondary)

                Text("À quelle heure veux-tu commencer ?")
                    .lumenFont(.title1)
                    .foregroundStyle(LumenColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            WheelTimePicker(selection: $vm.firstAlarmTime)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("alarm-time-picker")

            Text("Tu pourras changer plus tard.")
                .lumenFont(.callout)
                .foregroundStyle(LumenColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, LumenSpacing.l)
        .safeAreaInset(edge: .bottom) {
            PrimaryCTA("Programmer") {
                Task {
                    try? await vm.scheduleFirstAlarm()
                    onComplete()
                }
            }
            .accessibilityIdentifier("first-alarm-cta")
            .padding(.horizontal, LumenSpacing.l)
            .padding(.bottom, LumenSpacing.l)
            .background(LumenColor.bgPrimary)
        }
    }
}
