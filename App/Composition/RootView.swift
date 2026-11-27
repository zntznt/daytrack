import DaytrackCore
import SwiftUI

struct RootView: View {
    let state: AppState

    var body: some View {
        switch state.route {
        case .onboarding:
            Text("Daytrack") // placeholder until M3.03
        case .tabs:
            TabsView(today: LocalCalendar(timeZone: state.env.timeZone).dayKey(for: state.env.clock.now),
                     tab: state.env.screen == "settings" ? .settings : .today)
        case .unreadable(let keptAt):
            UnreadableView(keptAt: keptAt, onContinue: state.continueFromUnreadable)
        }
    }
}

/// History and Report join in M5.03 and M6.03 (Q7a).
struct TabsView: View {
    enum Tab: Hashable { case today, settings }

    let today: DayKey
    @State var tab: Tab

    var body: some View {
        TabView(selection: $tab) {
            SwiftUI.Tab("Today", systemImage: "sun.max", value: Tab.today) {
                Text(verbatim: today.isoString) // placeholder until M3.07
            }
            SwiftUI.Tab("Settings", systemImage: "gearshape", value: Tab.settings) {
                Text("Settings") // placeholder until M3.10
            }
        }
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
