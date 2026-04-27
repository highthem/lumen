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
