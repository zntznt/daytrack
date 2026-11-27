import SwiftUI

extension View {
    /// The one look for every list screen: the ambient backdrop behind the rows.
    /// Rows take `.listRowBackground(Tokens.surfaceRaised)` per section: on the List itself it does not reach them.
    func daytrackList() -> some View {
        scrollContentBackground(.hidden)
            // The marker lets UI tests check that no list screen misses the backdrop.
            .background(AmbientBackground().accessibilityElement().accessibilityIdentifier("daytrackList"))
    }
}
