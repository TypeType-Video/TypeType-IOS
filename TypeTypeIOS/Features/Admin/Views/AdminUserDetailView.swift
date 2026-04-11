import SwiftUI

struct AdminUserDetailView: View {
  let user: AdminUser
  let onRole: (AdminRole) -> Void
  let onSuspend: () -> Void
  let onResetToken: () -> Void

  private var createdAtText: String {
    guard user.createdAt.raw > 0 else { return "Unknown" }
    let date = Date(timeIntervalSince1970: TimeInterval(user.createdAt.raw / 1000))
    return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
  }

  var body: some View {
    Form {
      Section("Identity") {
        Text(user.name)
        Text(user.email)
          .foregroundStyle(.secondary)
        Text(user.id)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Section("State") {
        LabeledContent("Role", value: user.role.rawValue)
        LabeledContent("Suspended", value: user.suspended ? "Yes" : "No")
        LabeledContent("Verified", value: user.verified ? "Yes" : "No")
        LabeledContent("Created", value: createdAtText)
      }

      Section("Actions") {
        Menu("Change role") {
          ForEach(AdminRole.allCases, id: \.rawValue) { role in
            Button(role.rawValue.capitalized) { onRole(role) }
          }
        }
        Button(user.suspended ? "Unsuspend" : "Suspend") {
          onSuspend()
        }
        Button("Generate reset token") {
          onResetToken()
        }
      }
    }
    .navigationTitle("User")
    .navigationBarTitleDisplayMode(.inline)
  }
}
