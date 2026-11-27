import DaytrackCore
import SwiftUI

struct RootView: View {
    let state: AppState
    /// Set by Erase; "Start again" clears it and the empty record routes to onboarding.
    @State private var erased = false

    var body: some View {
        #if DEBUG
        if let screen = state.env.screen, screen != "settings" {
            DebugScreens.view(for: screen)
        } else {
            routed
        }
        #else
        routed
        #endif
    }

    @ViewBuilder private var routed: some View {
        if erased {
            ErasedView(noOtherCopy: Copy.eraseNoOtherCopy, onStartAgain: { erased = false })
        } else {
            switch state.route {
            case .onboarding:
                OnboardingContainer(trackers: state.trackers)
            case .tabs:
                TabsView(state: state, tab: state.env.screen == "settings" ? .settings : .today, onErased: { erased = true })
            case .unreadable(let keptAt):
                UnreadableView(keptAt: keptAt, onContinue: state.continueFromUnreadable)
            }
        }
    }
}

/// The screens Settings pushes. The board reaches Trackers only through `TabsView.showTrackers` (M8.02 reuses it).
enum SettingsRoute: Hashable { case trackers, archived }

/// History and Report join in M5.03 and M6.03 (Q7a).
struct TabsView: View {
    enum Tab: Hashable { case today, settings }

    let state: AppState
    @State var tab: Tab
    @State private var settingsPath: [SettingsRoute] = []
    let onErased: () -> Void

    var body: some View {
        TabView(selection: $tab) {
            SwiftUI.Tab("Today", systemImage: "sun.max", value: Tab.today) {
                // "Bring one back" lands on the archived list, where bring-back is (Q7a).
                TodayContainer(state: state, onBringBack: { showTrackers(archived: true) })
            }
            SwiftUI.Tab("Settings", systemImage: "gearshape", value: Tab.settings) {
                SettingsContainer(state: state, path: $settingsPath, onErased: onErased)
            }
        }
    }

    /// The one route from the board to Settings › Trackers, optionally on to its archived list.
    private func showTrackers(archived: Bool) {
        settingsPath = archived ? [.trackers, .archived] : [.trackers]
        tab = .settings
    }
}

/// Read-only: says the file was kept and where.
struct UnreadableView: View {
    let keptAt: URL
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Daytrack could not read its file").font(.title2.bold())
            Text("Nothing was deleted. The file was kept, unchanged, at:")
            Text(verbatim: keptAt.path).font(.footnote.monospaced()).textSelection(.enabled)
            Button("Continue", action: onContinue).buttonStyle(.borderedProminent)
        }
        .multilineTextAlignment(.center).padding()
    }
}
