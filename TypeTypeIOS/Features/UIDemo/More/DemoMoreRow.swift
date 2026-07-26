import SwiftUI

struct DemoMoreRow: View {
  let title: String
  let subtitle: String?
  let systemImage: String
  let tint: Color
  let showsChevron: Bool

  init(
    _ title: String,
    subtitle: String? = nil,
    systemImage: String,
    tint: Color,
    showsChevron: Bool = false
  ) {
    self.title = title
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.tint = tint
    self.showsChevron = showsChevron
  }

  var body: some View {
    HStack(spacing: 13) {
      Image(systemName: systemImage)
        .font(.body.weight(.semibold))
        .foregroundStyle(.white)
        .frame(width: 32, height: 32)
        .background(tint.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .foregroundStyle(.primary)
        if let subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      if showsChevron {
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }
    }
  }
}
