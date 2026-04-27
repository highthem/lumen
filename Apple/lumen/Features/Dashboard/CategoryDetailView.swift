import SwiftUI

struct CategoryDetailView: View {
    let category: DashboardCategory
    let onAskLumen: () -> Void

    @State private var todayContent: String = ""

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: LumenSpacing.l) {
                    SectionTitle(category.displayName)
                        .padding(.top, LumenSpacing.l)

                    // Today's entry
                    VStack(alignment: .leading, spacing: LumenSpacing.s) {
                        Eyebrow("Aujourd'hui")
                        ZStack(alignment: .topLeading) {
                            if todayContent.isEmpty {
                                Text("Ajoute une note…")
                                    .lumenFont(.body)
                                    .foregroundStyle(LumenColor.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $todayContent)
                                .lumenFont(.body)
                                .foregroundStyle(LumenColor.textPrimary)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(LumenSpacing.m)
                        .background(LumenColor.bgSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
                    }

                    // 7-day stub
                    VStack(alignment: .leading, spacing: LumenSpacing.m) {
                        Eyebrow("7 derniers jours")

                        ForEach(0..<7) { dayOffset in
                            HStack {
                                Text(dayLabel(offset: dayOffset))
                                    .lumenFont(.footnote)
                                    .foregroundStyle(LumenColor.textTertiary)
                                Spacer()
                                Text("—")
                                    .lumenFont(.footnote)
                                    .foregroundStyle(LumenColor.textTertiary)
                            }
                            .padding(.vertical, LumenSpacing.xs)
                        }
                    }

                    PrimaryCTA("Ask Lumen") {
                        onAskLumen()
                    }
                }
                .padding(.horizontal, LumenSpacing.l)
                .padding(.bottom, LumenSpacing.huge)
            }
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dayLabel(offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d"
        return formatter.string(from: date).capitalized
    }
}
