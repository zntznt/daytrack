import DaytrackCore
import SwiftUI

/// First run: the welcome, then the starter picker. Start writes the board; the route then moves to Today.
struct OnboardingContainer: View {
    let trackers: TrackerManager
    @State private var picking = false
    @State private var picks = StarterPicks()
    @State private var failure: String?

    var body: some View {
        if picking {
            StarterPickerView(starters: StarterCatalog.all, picked: picks.picked, canStart: picks.canStart,
                              reason: failure ?? picks.reason, onToggle: { picks.toggle($0) }, onStart: start)
        } else {
            WelcomeView(onPick: { picking = true })
        }
    }

    private func start() {
        do { try trackers.startBoard(picked: picks.picked) } catch TrackerError.refused(let reason) {
            failure = reason
        } catch {
            failure = error.localizedDescription
        }
    }
}
