#if DEBUG
import SwiftUI

/// DEBUG screens opened by `-uiTestScreen <name>`; `settings` is routed by RootView instead.
enum DebugScreens {
    @ViewBuilder static func view(for name: String) -> some View {
        switch name {
        case "catalog": CatalogView()
        default: Text(verbatim: "No debug screen named \(name)")
        }
    }
}
#endif
