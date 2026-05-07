#if DEBUG
import SwiftUI

struct ColorsCatalog: View {
    private struct Swatch: Identifiable {
        let id = UUID()
        let name: String
        let color: Color
        let group: String
    }

    private let swatches: [Swatch] = [
        .init(name: "bgPrimary",       color: LumenColor.bgPrimary,       group: "Background"),
        .init(name: "bgSecondary",     color: LumenColor.bgSecondary,     group: "Background"),
        .init(name: "bgTertiary",      color: LumenColor.bgTertiary,      group: "Background"),

        .init(name: "textPrimary",     color: LumenColor.textPrimary,     group: "Text"),
        .init(name: "textSecondary",   color: LumenColor.textSecondary,   group: "Text"),
        .init(name: "textTertiary",    color: LumenColor.textTertiary,    group: "Text"),

        .init(name: "accent",          color: LumenColor.accent,          group: "Accent"),
        .init(name: "accentMuted",     color: LumenColor.accentMuted,     group: "Accent"),

        .init(name: "success",         color: LumenColor.success,         group: "Status"),
        .init(name: "warning",         color: LumenColor.warning,         group: "Status"),
        .init(name: "error",           color: LumenColor.error,           group: "Status"),

        .init(name: "divider",         color: LumenColor.divider,         group: "Lines"),

        .init(name: "Splash.earth",       color: LumenColor.Splash.earth,       group: "Splash"),
        .init(name: "Splash.dawnTop",     color: LumenColor.Splash.dawnTop,     group: "Splash"),
        .init(name: "Splash.dawnBottom",  color: LumenColor.Splash.dawnBottom,  group: "Splash"),
    ]

    private var grouped: [(group: String, items: [Swatch])] {
        let order = ["Background", "Text", "Accent", "Status", "Lines", "Splash"]
        return order.map { g in (g, swatches.filter { $0.group == g }) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenSpacing.l) {
                ForEach(grouped, id: \.group) { section in
                    VStack(alignment: .leading, spacing: LumenSpacing.s) {
                        Eyebrow(section.group)
                        VStack(spacing: LumenSpacing.xs) {
                            ForEach(section.items) { swatch in
                                row(swatch)
                            }
                        }
                    }
                }
            }
            .padding(LumenSpacing.l)
        }
        .background(LumenColor.bgPrimary)
        .navigationTitle("Colors")
    }

    private func row(_ swatch: Swatch) -> some View {
        HStack(spacing: LumenSpacing.m) {
            RoundedRectangle(cornerRadius: LumenRadius.s, style: .continuous)
                .fill(swatch.color)
                .overlay(
                    RoundedRectangle(cornerRadius: LumenRadius.s, style: .continuous)
                        .strokeBorder(LumenColor.divider, lineWidth: LumenSize.hairline)
                )
                .frame(width: 64, height: 40)

            Text(swatch.name)
                .lumenFont(.callout)
                .foregroundStyle(LumenColor.textPrimary)
            Spacer()
        }
        .padding(.vertical, LumenSpacing.xs)
    }
}

#Preview("Light") {
    NavigationStack { ColorsCatalog() }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack { ColorsCatalog() }
        .preferredColorScheme(.dark)
}
#endif
