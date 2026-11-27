import SwiftUI

/// The warm content backdrop. Content, not glass.
struct AmbientBackground: View {
    var body: some View {
        LinearGradient(colors: [Tokens.surface, Tokens.background], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}
