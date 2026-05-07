import SwiftUI

struct LumenToggle: View {
    @Binding var isOn: Bool
    var label: String?

    var body: some View {
        Toggle(label ?? "", isOn: $isOn)
            .toggleStyle(.switch)
            .tint(LumenColor.accent)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var on = true
    @Previewable @State var off = false
    VStack(spacing: LumenSpacing.l) {
        LumenToggle(isOn: $on, label: "Voix lente")
        LumenToggle(isOn: $off, label: "Notifications")
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
