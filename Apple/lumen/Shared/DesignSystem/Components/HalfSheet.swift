import SwiftUI

struct HalfSheet<Content: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                content()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var open = false
    VStack(spacing: LumenSpacing.l) {
        PrimaryCTA("Open sheet") { open = true }
            .padding(.horizontal, LumenSpacing.l)
        HalfSheet(isPresented: $open) {
            VStack(spacing: LumenSpacing.l) {
                SectionTitle("Sheet content")
                Text("Demi-modale avec contenu serif et CTA de fermeture.")
                    .lumenFont(.bodySerif)
                    .foregroundStyle(LumenColor.textPrimary)
                    .multilineTextAlignment(.center)
                PrimaryCTA("Close") { open = false }
            }
            .padding(LumenSpacing.l)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LumenColor.bgPrimary)
}
#endif
