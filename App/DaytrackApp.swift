import SwiftUI

@main
struct DaytrackApp: App {
    @State private var state = AppState(AppEnvironment.launch())

    var body: some Scene {
        WindowGroup {
            RootView(state: state)
        }
    }
}
