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

                    detailContent

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

    @ViewBuilder
    private var detailContent: some View {
        switch category {
        case .sleep:
            sleepDetail
        case .presence:
            presenceDetail
        default:
            noteEditor
            sevenDayStub
        }
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow("Aujourd'hui")
            ZStack(alignment: .topLeading) {
                if todayContent.isEmpty {
                    Text("Ajoute une note…")
                        .lumenFont(.body)
                        .foregroundStyle(LumenColor.textTertiary)
                        .padding(.top, LumenSpacing.s)
                        .padding(.leading, LumenSpacing.xs)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $todayContent)
                    .lumenFont(.body)
                    .foregroundStyle(LumenColor.textPrimary)
                    .frame(minHeight: LumenSize.editorMin)
                    .scrollContentBackground(.hidden)
            }
            .padding(LumenSpacing.m)
            .background(LumenColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
        }
    }

    private var sevenDayStub: some View {
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
    }

    private var presenceDetail: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.m) {
            Eyebrow("Présence")
            Text("60 secondes de présence avant le rituel — pour calmer le souffle, pas pour performer.")
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var sleepDetail: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.m) {
            Eyebrow("Sommeil")
            Text("Lumen lit ton sommeil depuis Apple Santé. Tes données restent sur ton téléphone.")
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Voir dans Apple Santé →")
                    .lumenFont(.body)
                    .foregroundStyle(LumenColor.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private func dayLabel(offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d"
        return formatter.string(from: date).capitalized
    }
}
