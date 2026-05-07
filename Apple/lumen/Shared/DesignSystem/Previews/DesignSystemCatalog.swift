#if DEBUG
import SwiftUI

/// Top-level browser for the Lumen design system. Lives in Xcode previews
/// only — not wired into the running app. Open this file and hit Resume to
/// browse colors, typography, spacing, radii, shadows, opacity, sizes,
/// motion, icon fonts, and every component.
struct DesignSystemCatalog: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Tokens") {
                    NavigationLink("Colors")     { ColorsCatalog() }
                    NavigationLink("Typography") { TypographyCatalog() }
                    NavigationLink("Spacing")    { SpacingCatalog() }
                    NavigationLink("Radii")      { RadiiCatalog() }
                    NavigationLink("Shadows")    { ShadowsCatalog() }
                    NavigationLink("Opacity")    { OpacityCatalog() }
                    NavigationLink("Sizes")      { SizesCatalog() }
                    NavigationLink("Motion")     { MotionCatalog() }
                    NavigationLink("Icon Fonts") { IconFontsCatalog() }
                }
                Section("Components") {
                    NavigationLink("All components (\(ComponentEntry.allCases.count))") {
                        ComponentsIndex()
                    }
                }
            }
            .navigationTitle("Design System")
        }
    }
}

#Preview("Light") {
    DesignSystemCatalog()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DesignSystemCatalog()
        .preferredColorScheme(.dark)
}
#endif
