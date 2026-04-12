import Foundation

struct ResetPasswordPayload: Encodable {
  let resetToken: String
  let newPassword: String
}
