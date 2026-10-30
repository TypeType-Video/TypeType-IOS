import Foundation

extension AuthRole {
  var title: String {
    switch self {
    case .admin: String(localized: "Administrator")
    case .moderator: String(localized: "Moderator")
    case .user: String(localized: "Member")
    default: rawValue.capitalized
    }
  }
}
