import SwiftUI

struct AskLumenView: View {
    @State var vm: AskLumenViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                LumenColor.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: LumenSpacing.l) {
                        SectionTitle("Ask Lumen")
                            .padding(.top, LumenSpacing.m)

                        if let category = vm.category {
                            Eyebrow(category.displayName)
                        }

                        // Question input
                        ZStack(alignment: .topLeading) {
                            if vm.question.isEmpty {
                                Text("Pose ta question…")
                                    .lumenFont(.body)
                                    .foregroundStyle(LumenColor.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $vm.question)
                                .lumenFont(.body)
                                .foregroundStyle(LumenColor.textPrimary)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(LumenSpacing.m)
                        .background(LumenColor.bgSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))

                        // Response area
                        switch vm.state {
                        case .idle:
                            EmptyView()
                        case .loading:
                            HStack {
                                Spacer()
                                ProgressView().tint(LumenColor.accent)
                                Spacer()
                            }
                        case .ready(let aiResponse):
                            responseView(response: aiResponse)
                        case .rateLimited:
                            Text("Limite atteinte pour aujourd'hui — reviens demain.")
                                .lumenFont(.body)
                                .foregroundStyle(LumenColor.textSecondary)
                                .multilineTextAlignment(.center)
                        case .error(let msg):
                            Text(msg)
                                .lumenFont(.footnote)
                                .foregroundStyle(LumenColor.error)
                        }

                        PrimaryCTA(
                            "Demander",
                            isEnabled: !vm.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ) {
                            Task { await vm.ask() }
                        }
                    }
                    .padding(.horizontal, LumenSpacing.l)
                    .padding(.bottom, LumenSpacing.huge)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { isPresented = false }
                        .foregroundStyle(LumenColor.textSecondary)
                }
            }
        }
    }

    private func responseView(response: AIResponse) -> some View {
        VStack(alignment: .leading, spacing: LumenSpacing.m) {
            Divider().overlay(LumenColor.divider)

            VStack(alignment: .leading, spacing: LumenSpacing.s) {
                Eyebrow("RÉPONSE")
                Text(response.intention)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(LumenColor.textPrimary)
                    .lineSpacing(LumenFont.body.lineSpacing)
            }

            if !response.focus.isEmpty {
                VStack(alignment: .leading, spacing: LumenSpacing.s) {
                    Eyebrow("DÉTAIL")
                    Text(response.focus.joined(separator: "\n"))
                        .lumenFont(.body)
                        .foregroundStyle(LumenColor.textSecondary)
                }
            }

            if response.provider == .apple {
                HStack {
                    AppleIntelligenceBadge()
                    Spacer()
                }
            }
        }
    }
}
