import SwiftUI

struct LiveAdminAccessUserRow: View {
  @Environment(\.themePalette) private var palette
  let user: LiveAdminAllowListUser

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "person.crop.circle")
        .font(.title2)
        .foregroundStyle(palette.accent)
      VStack(alignment: .leading, spacing: 2) {
        Text(user.name)
          .font(.body.weight(.semibold))
          .foregroundStyle(.primary)
        Text(user.email)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Text(
        user.accessMode == "allow_list"
          ? "Restricted"
          : "Unrestricted"
      )
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
    }
    .contentShape(Rectangle())
  }
}
