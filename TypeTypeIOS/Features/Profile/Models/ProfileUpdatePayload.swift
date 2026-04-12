import Foundation

struct ProfileUpdatePayload: Encodable {
  let publicUsername: String?
  let bio: String?
}
