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
                        .frame(width: 36, height: 5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    Eyebrow("Ask Lumen")

                    if let category = vm.category {
                        HStack(spacing: 0) {
                            Text("Catégorie · \(category.displayName)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(LumenColor.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(LumenColor.bgTertiary)
                                .clipShape(Capsule())
                        }
                    }

                    // Question input — text field + mic affordance
                    HStack(alignment: .top, spacing: 10) {
                        ZStack(alignment: .topLeading) {
                            if vm.question.isEmpty {
                                Text("Pose ta question…")
                                    .font(.system(size: 19, design: .serif))
                                    .foregroundStyle(LumenColor.textTertiary)
                                    .padding(.top, 14)
                                    .padding(.leading, 18)
                                    .allowsHitTesting(false)
                            }
                            TextField("", text: $vm.question, axis: .vertical)
                                .lineLimit(2...5)
                                .font(.system(size: 19, design: .serif))
                                .foregroundStyle(LumenColor.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(minHeight: 84, alignment: .topLeading)
                                .background(LumenColor.bgSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(LumenColor.divider, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        AskMicButton(state: vm.micState,
                                     onPressDown: { vm.startDictation() },
                                     onPressUp: { Task { await vm.stopDictation() } })
                    }

                    if vm.micState == .listening {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(LumenColor.accent)
                                .frame(width: 7, height: 7)
                            Text("on écoute")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(LumenColor.accent.opacity(0.85))
                            Spacer()
                        }
                    }

                    // Response area
                    Group {
                        switch vm.state {
                        case .idle:
                            EmptyView()
                        case .loading:
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(LumenColor.accent)
                                    .frame(width: 5, height: 5)
                                Text("Lumen écrit…")
                                    .font(.system(size: 13, design: .serif))
                                    .italic()
                                    .foregroundStyle(LumenColor.textSecondary)
                            }
                        case .ready(let aiResponse):
                            responseView(response: aiResponse)
                        case .rateLimited:
                            Text("Limite atteinte pour aujourd'hui — reviens demain.")
                                .font(.system(size: 16, design: .serif))
                                .italic()
                                .foregroundStyle(LumenColor.textSecondary)
                                .multilineTextAlignment(.leading)
                        case .error(let msg):
                            Text(msg)
                                .lumenFont(.footnote)
                                .foregroundStyle(LumenColor.error)
                        }
                    }

                    Spacer(minLength: 16)

                    HStack {
                        Text("\(vm.remainingAsks) / 3 questions restantes")
                            .font(.system(size: 12))
                            .foregroundStyle(LumenColor.textTertiary)
                        Spacer()
                        Button("Fermer") { isPresented = false }
                            .font(.system(size: 12))
                            .foregroundStyle(LumenColor.textSecondary)
                    }

                    PrimaryCTA(
                        "Demander",
                        isEnabled: !vm.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        Task { await vm.ask() }
                    }
                }
                .padding(.horizontal, LumenSpacing.l)
                .padding(.bottom, LumenSpacing.l)
            }
        }
        .task { await vm.loadRemaining() }
    }

    private func responseView(response: AIResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question echo
            Text(vm.question)
                .font(.system(size: 22, weight: .medium, design: .serif))
                .tracking(-0.11)
                .lineSpacing(2)
                .foregroundStyle(LumenColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Answer
            Text(response.intention)
                .font(.system(size: 17, design: .serif))
                .italic()
                .lineSpacing(3)
                .foregroundStyle(LumenColor.textPrimary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            if response.provider == .apple {
                HStack {
                    AppleIntelligenceBadge()
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
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

    private let size: CGFloat = 44

    var body: some View {
        ZStack {
            Group {
                if state == .listening {
                    Circle().fill(LumenColor.accent)
                } else {
                    Circle()
                        .fill(LumenColor.accent.opacity(0.12))
                        .overlay(Circle().strokeBorder(LumenColor.accent, lineWidth: 1.2))
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(state == .listening && !reduceMotion ? breath : 1.0)

            Image(systemName: "mic.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(state == .listening ? LumenColor.bgPrimary : LumenColor.accent)
        }
        .frame(width: size + 12, height: size + 12)
        .contentShape(Circle())
        .onChange(of: state) { _, newState in
            if newState == .listening && !reduceMotion {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    breath = 1.06
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
