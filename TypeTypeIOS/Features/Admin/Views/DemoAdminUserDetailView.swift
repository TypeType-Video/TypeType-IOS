import SwiftUI
import UIKit

struct DemoAdminUserDetailView: View {
  @EnvironmentObject private var session: DemoSessionStore
  let userID: String
  @State private var name = ""
  @State private var email = ""
  @State private var resetToken: String?

  var body: some View {
    Form {
      if user != nil {
        Section {
          TextField("Display name", text: $name)
          TextField("Email address", text: $email)
            .textInputAutocapitalization(.never)
          Button("Save identity", action: saveIdentity)
            .disabled(name.isEmpty || !email.contains("@"))
        } header: { Text("Identity").liveSectionHeader() }

        Section {
          Picker("Role", selection: roleBinding) {
            Text("User").tag("user")
            Text("Moderator").tag("moderator")
            Text("Admin").tag("admin")
          }
          Toggle("Suspended", isOn: suspendedBinding)
          Toggle("Verified", isOn: verifiedBinding)
        } header: { Text("Role and status").liveSectionHeader() }

        Section {
          NavigationLink("Configure user allow list") {
            DemoAdminUserAllowListView(userID: userID)
          }
        } header: { Text("Access").liveSectionHeader() }

        Section {
          Button("Reset token") {
            resetToken = "mock-\(UUID().uuidString.prefix(12))"
          }
          if let resetToken {
            LabeledContent("One-time token", value: resetToken)
              .textSelection(.enabled)
            Button("Copy token") {
              UIPasteboard.general.string = resetToken
            }
          }
        } header: { Text("Actions").liveSectionHeader() }
      } else {
        ContentUnavailableView("User not found", systemImage: "person.slash")
      }
    }
    .navigationTitle(user?.name ?? "User")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear(perform: loadDraft)
  }

  private var index: Int? {
    session.adminUsers.firstIndex { $0.id == userID }
  }

  private var user: DemoAdminUser? {
    index.map { session.adminUsers[$0] }
  }

  private var roleBinding: Binding<String> {
    userBinding(\.role, fallback: "user")
  }

  private var suspendedBinding: Binding<Bool> {
    userBinding(\.isSuspended, fallback: false)
  }

  private var verifiedBinding: Binding<Bool> {
    userBinding(\.isVerified, fallback: false)
  }

  private func userBinding<Value>(
    _ keyPath: WritableKeyPath<DemoAdminUser, Value>,
    fallback: Value
  ) -> Binding<Value> {
    Binding(
      get: { user?[keyPath: keyPath] ?? fallback },
      set: { value in
        guard let index else { return }
        session.adminUsers[index][keyPath: keyPath] = value
      }
    )
  }

  private func loadDraft() {
    name = user?.name ?? ""
    email = user?.email ?? ""
  }

  private func saveIdentity() {
    guard let index else { return }
    session.adminUsers[index].name = name
    session.adminUsers[index].email = email
  }
}
