import SwiftUI

struct OnboardingFirstAlarmView: View {
    @Bindable var vm: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            Spacer().frame(height: LumenSpacing.xl)

            Text("04 / 04")
                .lumenFont(.caption)
                .textCase(.uppercase)
                .foregroundStyle(LumenColor.textSecondary)

            Spacer().frame(height: LumenSpacing.m)

            Text("À quelle heure veux-tu commencer ?")
                .lumenFont(.title1)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: LumenSpacing.xl)

            WheelTimePicker(selection: $vm.firstAlarmTime)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("alarm-time-picker")

            Spacer().frame(height: LumenSpacing.m)

            Text("Tu pourras changer plus tard.")
                .lumenFont(.callout)
                .foregroundStyle(LumenColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            PrimaryCTA("Programmer") {
                Task {
                    try? await vm.scheduleFirstAlarm()
                    onComplete()
                }
            }
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.bottom, LumenSpacing.xl)
    }
}
