import SwiftUI
import SwiftData

@main
struct DasAlteDresdenApp: App {
    @State private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appEnvironment)
                .modelContainer(LocalStore.shared.container)
        }
    }
}
