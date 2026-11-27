import SwiftUI
import UserNotifications

@main
struct DaytrackApp: App {
    @State private var state: AppState
    @State private var actions: NotificationActionHandler

    init() {
        let state = AppState(AppEnvironment.launch())
        let actions = NotificationActionHandler(recorder: state.recorder, clock: state.env.clock, tz: state.env.timeZone)
        // Set before launch ends, so an action that launched the app still arrives.
        UNUserNotificationCenter.current().delegate = actions
        (_state, _actions) = (State(initialValue: state), State(initialValue: actions))
    }

    var body: some Scene {
        WindowGroup {
            // A new identity on each Open puts the tabs back on Today.
            RootView(state: state).id(actions.opens)
                .sheet(isPresented: Binding(get: { actions.route == .amend }, set: { if !$0 { actions.route = nil } })) {
                    AmendContainer(state: state, onBringBack: { actions.route = nil })
                }
        }
    }
}
