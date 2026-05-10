import SwiftUI

struct PrimaryCTA<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            label()
                .lumenFont(.body)
                .foregroundStyle(LumenColor.bgPrimary)
                .padding(.horizontal)
        }
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(LumenColor.accent)
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous))
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }
}

extension PrimaryCTA where Label == Text {
    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.action = action
        self.label = { Text(title) }
        self.isEnabled = isEnabled
    }
}

#if DEBUG
#Preview {
    VStack(spacing: LumenSpacing.l) {
        PrimaryCTA("Continuer") { print("Tapped") }
        PrimaryCTA("Continuer", isEnabled: false) {}
    }
    .padding(LumenSpacing.l)
    .background(LumenColor.bgPrimary)
}
#endif
