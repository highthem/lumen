import SwiftUI

struct Q1MoodView: View {
    @Bindable var vm: QuestionnaireFlowViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    private static let tags: [String] = ["enfoui", "fragile", "posé", "vif", "rayonnant"]
    private static let subs: [String] = [
        "pesant, lent à se lever",
        "le souffle est court",
        "le souffle est régulier",
        "présent, alerte",
        "plein, ouvert"
    ]

    @State private var hasInteracted: Bool = false

    var body: some View {
        ChromaticSlider(
            level: Binding(
                get: { vm.moodLevel },
                set: {
                    vm.moodLevel = $0
                    vm.moodTag = Self.tags[$0]
                    hasInteracted = true
                }
            )
        ) { ink in
            content(ink: ink)
        }
        .onAppear {
            // Pre-fill the tag so a single tap to advance is valid.
            if vm.moodTag == nil {
                vm.moodTag = Self.tags[vm.moodLevel]
            }
        }
        // Tap (no drag) advances to the next step. The chromatic slider
        // handles drag-to-change-level above; tap stays separate.
        .simultaneousGesture(
            TapGesture().onEnded { onNext() }
        )
    }

    @ViewBuilder
    private func content(ink: Color) -> some View {
        ZStack {
            // Top — progress + eyebrow (matches `.q1-topbar`)
            VStack(alignment: .leading, spacing: 16) {
                ProgressDots4(current: 0)
                    .tint(ink)
                Eyebrow("01 / 04 · Ressenti")
                    .foregroundStyle(ink.opacity(0.75))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 24)
            .padding(.top, 14)

            // Centre — kinetic word
            VStack(spacing: 18) {
                Text("Aujourd'hui je me sens")
                    .font(.system(size: 11))
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.55))

                Text(Self.tags[vm.moodLevel])
                    .font(.system(size: 64, weight: .medium, design: .serif))
                    .italic()
                    .tracking(-1.6)
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .id(vm.moodLevel)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 6)),
                        removal: .opacity
                    ))
                    .animation(.easeOut(duration: 0.30), value: vm.moodLevel)

                Text(Self.subs[vm.moodLevel])
                    .font(.system(size: 15, design: .serif))
                    .italic()
                    .foregroundStyle(ink.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                    .id("sub-\(vm.moodLevel)")
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.30), value: vm.moodLevel)
            }
            .padding(.horizontal, 32)

            // Right rail — 5 dots stacked vertically (mirrors `.q1-rail`)
            VStack(spacing: 36) {
                ForEach((0..<5).reversed(), id: \.self) { i in
                    Circle()
                        .fill(ink)
                        .opacity(opacityForTick(index: i))
                        .frame(width: 6, height: 6)
                        .scaleEffect(i == vm.moodLevel ? 1.8 : 1.0)
                        .animation(.easeOut(duration: 0.25), value: vm.moodLevel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .padding(.trailing, 22)

            // Top hint — "↑ rayonnant" (hidden at max level)
            if vm.moodLevel != 4 {
                hintLabel(text: "rayonnant", chevronUp: true, ink: ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 96)
            }

            // Bottom hint — "↓ enfoui" (hidden at min level)
            if vm.moodLevel != 0 {
                hintLabel(text: "enfoui", chevronUp: false, ink: ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 96)
            }

            // Subtle "Tap pour valider" hint, appears once the user dragged
            if hasInteracted {
                Text("Tap pour valider")
                    .font(.system(size: 11))
                    .tracking(2.0)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.55))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 36)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.4), value: hasInteracted)
            }
        }
    }

    private func opacityForTick(index: Int) -> Double {
        if index == vm.moodLevel { return 1.0 }
        if index < vm.moodLevel { return 0.55 }
        return 0.28
    }

    private func hintLabel(text: String, chevronUp: Bool, ink: Color) -> some View {
        VStack(spacing: 6) {
            if chevronUp {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .medium))
                Text(text)
                    .font(.system(size: 11))
                    .tracking(2.0)
                    .textCase(.uppercase)
            } else {
                Text(text)
                    .font(.system(size: 11))
                    .tracking(2.0)
                    .textCase(.uppercase)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
            }
        }
        .foregroundStyle(ink.opacity(0.42))
    }
}
