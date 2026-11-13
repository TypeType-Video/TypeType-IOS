import Foundation

enum LiveUserError: Equatable {
  case offline
  case instanceUnreachable
  case serverSlow
  case providerBlocked
  case contentBlocked
  case membersOnly
  case ageRestricted
  case privateContent
  case contentUnavailable
  case signInAgain
  case permissionDenied
  case conflict
  case rateLimited
  case serverUnavailable
  case other

  init(_ error: Error, online: Bool = true) {
    if let urlError = error as? URLError {
      self = Self.classify(urlError.code, online: online)
      return
    }
    switch error as? NetworkError {
    case let .statusCode(status, _, code):
      self = Self.classify(code: code, status: status)
    case .transport:
      self = online ? .instanceUnreachable : .offline
    case .missingAccessToken:
      self = .signInAgain
    default:
      self = .other
    }
  }

  static func classify(code: String?, status: Int) -> LiveUserError {
    switch code?.lowercased() {
    case "provider_access_blocked", "token_service_unavailable": .providerBlocked
    case "rate_limited", "too_many_attempts": .rateLimited
    case "upstream_timeout", "sabr_upstream_timeout": .serverSlow
    case "content_blocked": .contentBlocked
    case "members_only": .membersOnly
    case "age_restricted": .ageRestricted
    case "private_content": .privateContent
    case "content_unavailable": .contentUnavailable
    case "authentication_required", "invalid_token", "unauthorized": .signInAgain
    default: classify(status: status)
    }
  }

  private static func classify(status: Int) -> LiveUserError {
    switch status {
    case 401: .signInAgain
    case 403: .permissionDenied
    case 404, 410: .contentUnavailable
    case 408, 504: .serverSlow
    case 409: .conflict
    case 429: .rateLimited
    case 500...599: .serverUnavailable
    default: .other
    }
  }

  private static func classify(_ code: URLError.Code, online: Bool) -> LiveUserError {
    switch code {
    case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff: .offline
    case .timedOut: .serverSlow
    default: online ? .instanceUnreachable : .offline
    }
  }

  var isProviderBlock: Bool { self == .providerBlocked }

  var message: String? {
    switch self {
    case .offline: String(localized: "You are offline. Check your connection and try again.")
    case .instanceUnreachable: String(localized: "The instance could not be reached. It may be down or too slow right now.")
    case .serverSlow: String(localized: "The instance is taking too long to answer. Try again in a moment.")
    case .providerBlocked: String(localized: "YouTube is refusing requests from this instance right now. Try again later.")
    case .contentBlocked: String(localized: "This is blocked for this account, or outside the family list.")
    case .membersOnly: String(localized: "This video is for channel members only.")
    case .ageRestricted: String(localized: "This video is age-restricted.")
    case .privateContent: String(localized: "This video is private.")
    case .contentUnavailable: String(localized: "This content is no longer available.")
    case .signInAgain: String(localized: "Sign in again to continue.")
    case .permissionDenied: String(localized: "Your account cannot do this.")
    case .conflict: String(localized: "This changed elsewhere. Refresh and try again.")
    case .rateLimited: String(localized: "Too many requests. Try again in a moment.")
    case .serverUnavailable: String(localized: "The instance cannot complete this request right now.")
    case .other: nil
    }
  }
}

extension NetworkError {
  // A provider block lasts minutes or hours on the instance: retrying only delays the message.
  var isProviderBlock: Bool {
    guard case let .statusCode(status, _, code) = self else { return false }
    return LiveUserError.classify(code: code, status: status) == .providerBlocked
  }
}
