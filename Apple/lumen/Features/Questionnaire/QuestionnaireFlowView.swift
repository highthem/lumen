import SwiftUI

struct QuestionnaireFlowView: View {
    @State var vm: QuestionnaireFlowViewModel
    let onComplete: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            stepView
                .transition(
                    reduceMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                )
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.35),
                    value: vm.step
                )
        }
        .task { await vm.start() }
    }

    @ViewBuilder
    private var stepView: some View {
        switch vm.step {
        case .mood:
            Q1MoodView(
                vm: vm,
                onNext: { Task { try? await vm.advance() } },
                onBack: { vm.goBack() }
            )
        case .priority:
            Q2PriorityView(
                vm: vm,
                onNext: { Task { try? await vm.advance() } },
                onBack: { vm.goBack() }
            )
        case .gratitude:
            Q3GratitudeView(
                vm: vm,
                onNext: { Task { try? await vm.advance() } },
                onBack: { vm.goBack() }
            )
        case .intention:
            Q4IntentionView(
                vm: vm,
                onNext: {
                    Task {
                        try? await vm.saveCurrent()
                        UserDefaults.standard.set(true, forKey: "lumen.hasAnyRitual")
                        if let ritualId = vm.ritual?.id {
                            onComplete(ritualId)
                        }
                    }
                },
                onBack: { vm.goBack() }
            )
        }
    }
}
