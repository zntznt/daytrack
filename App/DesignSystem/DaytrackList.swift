import SwiftUI

extension View {
    /// The one look for every list screen: the ambient backdrop and warm rows instead of the system grey.
    func daytrackList() -> some View {
        scrollContentBackground(.hidden)
            .listRowBackground(Tokens.surfaceRaised)
            // The marker lets UI tests check that no list screen misses the backdrop.
            .background(AmbientBackground().accessibilityElement().accessibilityIdentifier("daytrackList"))
    }
}
