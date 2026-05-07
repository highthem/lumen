import SwiftUI

struct AskLumenView: View {
    @State var vm: AskLumenViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .top) {
            LumenColor.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: LumenSpacing.l) {
                    // Drag indicator
                    Capsule()
                        .fill(LumenColor.bgTertiary)
                        .frame(width: LumenSize.handleWidth, height: LumenSize.handleHeight)
                        .frame(maxWidth: .infinity)
                        .padding(.top, LumenSpacing.s)

                    Eyebrow("Ask Lumen")

                    if let category = vm.category {
                        HStack(spacing: 0) {
                            Text("Catégorie · \(category.displayName)")
                                .lumenFont(.footnote)
                                .fontWeight(.medium)
                                .foregroundStyle(LumenColor.textSecondary)
                                .padding(.horizontal, LumenSpacing.sm2)
                                .padding(.vertical, LumenSpacing.xs2)
                                .background(LumenColor.bgTertiary)
                                .clipShape(Capsule())
                        }
                    }

                    // Question input — text field + mic affordance
                    HStack(alignment: .top, spacing: LumenSpacing.sm) {
                        ZStack(alignment: .topLeading) {
                            if vm.question.isEmpty {
                                Text("Pose ta question…")
                                    .lumenFont(.bodySerifLg)
                                    .foregroundStyle(LumenColor.textTertiary)
                                    .padding(.top, LumenSpacing.sm3)
                                    .padding(.leading, LumenSpacing.ml)
                                    .allowsHitTesting(false)
                            }
                            TextField("", text: $vm.question, axis: .vertical)
                                .lineLimit(2...5)
                                .lumenFont(.bodySerifLg)
                                .foregroundStyle(LumenColor.textPrimary)
                                .padding(.horizontal, LumenSpacing.sm3)
                                .padding(.vertical, LumenSpacing.sm2)
                                .frame(minHeight: LumenSize.formInput, alignment: .topLeading)
                                .background(LumenColor.bgSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                                        .stroke(LumenColor.divider, lineWidth: LumenSize.hairline)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
                                .accessibilityIdentifier("ask-lumen-input")
                        }

                        AskMicButton(state: vm.micState,
                                     onPressDown: { vm.startDictation() },
                                     onPressUp: { Task { await vm.stopDictation() } })
                    }

                    if vm.micState == .listening {
                        HStack(spacing: LumenSpacing.s) {
                            Circle()
                                .fill(LumenColor.accent)
                                .frame(width: LumenSize.dotLg, height: LumenSize.dotLg)
                            Text("on écoute")
                                .lumenFont(.footnote)
                                .fontWeight(.medium)
                                .foregroundStyle(LumenColor.accent.opacity(LumenOpacity.pressed))
                            Spacer()
                        }
                    }

                    // Response area
                    Group {
                        switch vm.state {
                        case .idle:
                            EmptyView()
                        case .loading:
                            HStack(spacing: LumenSpacing.xs2) {
                                Circle()
                                    .fill(LumenColor.accent)
                                    .frame(width: LumenSize.dotSm, height: LumenSize.dotSm)
                                Text("Lumen écrit…")
                                    .lumenFont(.footnoteSerif)
                                    .italic()
                                    .foregroundStyle(LumenColor.textSecondary)
                            }
                        case .ready(let aiResponse):
                            responseView(response: aiResponse)
                        case .rateLimited:
                            Text("Limite atteinte pour aujourd'hui — reviens demain.")
                                .lumenFont(.bodySerifSm)
                                .italic()
                                .foregroundStyle(LumenColor.textSecondary)
                                .multilineTextAlignment(.leading)
                        case .error(let msg):
                            Text(msg)
                                .lumenFont(.footnote)
                                .foregroundStyle(LumenColor.error)
                        }
                    }

                    Spacer(minLength: LumenSpacing.m)

                    HStack {
                        Text("\(vm.remainingAsks) / 3 questions restantes")
                            .lumenFont(.footnote)
                            .foregroundStyle(LumenColor.textTertiary)
                        Spacer()
                        Button("Fermer") { isPresented = false }
                            .lumenFont(.footnote)
                            .foregroundStyle(LumenColor.textSecondary)
                    }

                    PrimaryCTA(
                        "Demander",
                        isEnabled: !vm.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        Task { await vm.ask() }
                    }
                    .accessibilityIdentifier("ask-lumen-send")
                }
                .padding(.horizontal, LumenSpacing.l)
                .padding(.bottom, LumenSpacing.l)
            }
        }
        .task { await vm.loadRemaining() }
    }

    private func responseView(response: AIResponse) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.sm2) {
            // Question echo
            Text(vm.question)
                .lumenFont(.title2)
                .fontWeight(.medium)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Answer
            Text(response.intention)
                .lumenFont(.bodySerif)
                .italic()
                .lineSpacing(LumenLineSpacing.s)
                .foregroundStyle(LumenColor.textPrimary.opacity(LumenOpacity.pressed))
                .fixedSize(horizontal: false, vertical: true)

            if response.provider == .apple {
                HStack {
                    AppleIntelligenceBadge()
                    Spacer()
                }
                .padding(.top, LumenSpacing.xs)
            }
        }
        .accessibilityIdentifier("ask-lumen-response")
    }
}

// MARK: - Compact mic affordance for the question input

private struct AskMicButton: View {
    let state: MicState
    let onPressDown: () -> Void
    let onPressUp: () -> Void

    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breath: CGFloat = 1.0

    private static let breathScale: CGFloat = 1.06
    private let size: CGFloat = LumenSize.buttonSm

    var body: some View {
        ZStack {
            Group {
                if state == .listening {
                    Circle().fill(LumenColor.accent)
                } else {
                    Circle()
                        .fill(LumenColor.accent.opacity(LumenOpacity.surfaceFill))
                        .overlay(Circle().strokeBorder(LumenColor.accent, lineWidth: LumenSize.hairline))
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(state == .listening && !reduceMotion ? breath : 1.0)

            Image(systemName: "mic.fill")
                .font(LumenIconFont.xl)
                .foregroundStyle(state == .listening ? LumenColor.bgPrimary : LumenColor.accent)
        }
        .frame(width: size + LumenSpacing.sm2, height: size + LumenSpacing.sm2)
        .contentShape(Circle())
        .onChange(of: state) { _, newState in
            if newState == .listening && !reduceMotion {
                withAnimation(LumenAnimation.breath) {
                    breath = Self.breathScale
                }
            } else {
                breath = 1.0
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed { pressed = true; onPressDown() }
                }
                .onEnded { _ in
                    if pressed { pressed = false; onPressUp() }
                }
        )
        .accessibilityElement()
        .accessibilityLabel(state == .listening ? "Relâche pour arrêter la dictée" : "Maintiens pour dicter ta question")
        .accessibilityAddTraits(.isButton)
    }
}
