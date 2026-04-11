import SwiftUI

struct RegisterFormView: View {
  @Binding var name: String
  @Binding var email: String
  @Binding var password: String

  var body: some View {
    Section("Create Account") {
      TextField("Name", text: $name)
      TextField("Email", text: $email)
        .textInputAutocapitalization(.never)
        .keyboardType(.emailAddress)
        .autocorrectionDisabled()
      SecureField("Password", text: $password)
    }
  }
}
