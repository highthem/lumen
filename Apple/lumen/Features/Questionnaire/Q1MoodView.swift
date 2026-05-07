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

    private static let activeDotScale: CGFloat = 1.8

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
            VStack(alignment: .leading, spacing: LumenSpacing.m) {
                ProgressDots4(current: 0)
                    .tint(ink)
                Eyebrow("01 / 04 · Ressenti")
                    .foregroundStyle(ink.opacity(LumenOpacity.waveform))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, LumenSpacing.l)
            .padding(.top, LumenSpacing.sm3)

            // Centre — kinetic word
            VStack(spacing: LumenSpacing.ml) {
                Text("Aujourd'hui je me sens")
                    .lumenFont(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(LumenOpacity.ring))

                Text(Self.tags[vm.moodLevel])
                    .lumenFont(.heroDisplay)
                    .italic()
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .id(vm.moodLevel)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: LumenSpacing.xs2)),
                        removal: .opacity
                    ))
                    .animation(LumenAnimation.standard, value: vm.moodLevel)

                Text(Self.subs[vm.moodLevel])
                    .lumenFont(.calloutSerif)
                    .italic()
                    .foregroundStyle(ink.opacity(LumenOpacity.p60))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: LumenSize.cardForm)
                    .id("sub-\(vm.moodLevel)")
                    .transition(.opacity)
                    .animation(LumenAnimation.standard, value: vm.moodLevel)
            }
            .padding(.horizontal, LumenSpacing.xl)

            // Right rail — 5 dots stacked vertically (mirrors `.q1-rail`)
            VStack(spacing: LumenSpacing.xl2) {
                ForEach((0..<5).reversed(), id: \.self) { i in
                    Circle()
                        .fill(ink)
                        .opacity(opacityForTick(index: i))
                        .frame(width: LumenSize.dotMd, height: LumenSize.dotMd)
                        .scaleEffect(i == vm.moodLevel ? Self.activeDotScale : 1.0)
                        .animation(LumenAnimation.quick, value: vm.moodLevel)
                        .accessibilityIdentifier("mood-\(i)")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .padding(.trailing, LumenSpacing.ml2)

            // Top hint — "↑ rayonnant" (hidden at max level)
            if vm.moodLevel != 4 {
                hintLabel(text: "rayonnant", chevronUp: true, ink: ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, LumenSpacing.hero)
            }

            // Bottom hint — "↓ enfoui" (hidden at min level)
            if vm.moodLevel != 0 {
                hintLabel(text: "enfoui", chevronUp: false, ink: ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, LumenSpacing.hero)
            }

            // Subtle "Tap pour valider" hint, appears once the user dragged
            if hasInteracted {
                Text("Tap pour valider")
                    .lumenFont(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(LumenOpacity.ring))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, LumenSpacing.xl2)
                    .transition(.opacity)
                    .animation(LumenAnimation.standard, value: hasInteracted)
            }
        }
    }

    private func opacityForTick(index: Int) -> Double {
        if index == vm.moodLevel { return 1.0 }
        if index < vm.moodLevel { return LumenOpacity.ring }
        return LumenOpacity.p28
    }

    private func hintLabel(text: String, chevronUp: Bool, ink: Color) -> some View {
        VStack(spacing: LumenSpacing.xs2) {
            if chevronUp {
                Image(systemName: "chevron.up")
                    .font(LumenIconFont.xs)
                Text(text)
                    .lumenFont(.caption)
                    .textCase(.uppercase)
            } else {
                Text(text)
                    .lumenFont(.caption)
                    .textCase(.uppercase)
                Image(systemName: "chevron.down")
                    .font(LumenIconFont.xs)
            }
        }
        .foregroundStyle(ink.opacity(LumenOpacity.p42))
    }
}
