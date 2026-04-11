import SwiftUI

struct LoginFormView: View {
  @Binding var email: String
  @Binding var password: String

  var body: some View {
    Section("Sign In") {
      TextField("Email", text: $email)
        .textInputAutocapitalization(.never)
        .keyboardType(.emailAddress)
        .autocorrectionDisabled()
      SecureField("Password", text: $password)
    }
  }
}
