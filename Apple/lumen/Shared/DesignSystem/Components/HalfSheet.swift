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
