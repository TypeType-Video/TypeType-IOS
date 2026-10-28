import SwiftUI

struct LiveVideoMetadataHeader: View {
  let title: String

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.title2.weight(.bold))
        .textSelection(.enabled)
    }
  }
}
