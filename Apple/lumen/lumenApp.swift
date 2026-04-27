import SwiftUI
import SwiftData

@main
struct lumenApp: App {
    @State private var composition = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            RootView(composition: composition)
                .modelContainer(composition.modelContainer)
        }
    }
}
