import SwiftUI

struct LiveAdminUserRow: View {
  let user: LiveAdminUser

  var body: some View {
    HStack(spacing: 12) {
      LiveRemoteImage(url: user.avatarURL)
        .frame(width: 44, height: 44)
        .clipShape(Circle())
      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text(user.name)
            .font(.headline)
          if user.suspended {
            Text("Suspended")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.red)
          }
        }
        Text(user.email)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(user.role.capitalized)
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      Spacer()
      Image(systemName: "chevron.right")
        .foregroundStyle(.tertiary)
    }
    .contentShape(Rectangle())
    .accessibilityIdentifier("live.admin.user")
  }
}
