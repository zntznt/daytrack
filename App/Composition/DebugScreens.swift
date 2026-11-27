#if DEBUG
import SwiftUI

/// Screens opened directly by `-uiTestScreen <name>`. Later tasks add their screens here.
enum DebugScreens {
    @ViewBuilder static func view(for screen: String) -> some View {
        switch screen {
        case "catalog": CatalogView()
        default: Text(verbatim: "No debug screen named \(screen)")
        }
    }
}
#endif
