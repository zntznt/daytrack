#if DEBUG
import SwiftUI

/// DEBUG: the type scale, colour tokens and native glass controls over the ambient background.
struct CatalogView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Typography.allCases, id: \.self) { role in
                        Text(verbatim: role.numerals ? "\(role) 0123456789" : "\(role)")
                            .typography(role).foregroundStyle(Tokens.text)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Tokens.all, id: \.name) { token in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12).fill(token.color).frame(width: 44, height: 44)
                            Text(verbatim: token.name).typography(.caption).foregroundStyle(Tokens.textSecondary)
                        }
                    }
                }
                HStack(spacing: 12) {
                    Button("Glass") {}.buttonStyle(.glass)
                    Button {} label: { Text("Prominent").foregroundStyle(Tokens.background) }.buttonStyle(.glassProminent)
                }
                HStack(spacing: 8) {
                    ForEach(["Chip 1", "Chip 2", "Chip 3"], id: \.self) { chip in
                        Button(chip) {}.buttonStyle(.glass)
                    }
                }
            }
            .padding(.horizontal, 22).padding(.top, 26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AmbientBackground())
        .tint(Tokens.accent)
        .controlSize(.large)
        .preferredColorScheme(.dark)
    }
}
#endif
