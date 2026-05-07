import SwiftUI

struct SecondaryCTA<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            label()
                .lumenFont(.body)
                .foregroundStyle(LumenColor.accent)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(.clear)
        .overlay(
            RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                .strokeBorder(LumenColor.accent, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }
}

extension SecondaryCTA where Label == Text {
    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.action = action
        self.label = { Text(title) }
        self.isEnabled = isEnabled
    }
}

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        SecondaryCTA("Plus tard") {}
        SecondaryCTA("Plus tard", isEnabled: false) {}
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
