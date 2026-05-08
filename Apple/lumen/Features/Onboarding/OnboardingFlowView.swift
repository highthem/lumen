import SwiftUI

struct OnboardingFlowView: View {
    @State var vm: OnboardingViewModel
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            switch vm.step {
            case .welcome:
                OnboardingWelcomeView(vm: vm)
                    .transition(pageTransition)
            case .pitch:
                OnboardingPitchView(vm: vm)
                    .transition(pageTransition)
            case .permissions:
                OnboardingPermissionsView(vm: vm)
                    .transition(pageTransition)
            case .firstAlarm:
                OnboardingFirstAlarmView(vm: vm, onComplete: onComplete)
                    .transition(pageTransition)
            }
        }
        .animation(reduceMotion ? .default : LumenAnimation.standard, value: vm.step)
    }

    private var pageTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

#if DEBUG
#Preview {
    OnboardingFlowView(vm: .preview, onComplete: {})
        .preferredColorScheme(.dark)
}
#endif
