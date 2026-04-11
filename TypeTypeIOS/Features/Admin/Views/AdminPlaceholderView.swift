import SwiftUI

struct AdminPlaceholderView: View {
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Text("Admin Console")
          .font(.title2.weight(.semibold))
        Text("Scaffold ready. UI implementation starts here.")
          .foregroundStyle(.secondary)
        Spacer()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .navigationTitle("Admin")
    }
  }
}
