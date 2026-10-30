import Foundation

struct InstanceMetadata: Decodable, Equatable {
  let name: String
  let tagline: String?
  let version: String
  let apiVersion: Int
  let registrationAllowed: Bool
  let guestAllowed: Bool
  let supportedServices: [Int]
  let logoURL: URL?
  let bannerURL: URL?
  let localLoginEnabled: Bool
  let oidcEnabled: Bool
  let oidcProviderName: String?
  let oidcAutoRedirect: Bool
  let youtubeRemoteLoginEnabled: Bool
  let youtubeRemoteLoginReady: Bool
  let youtubeRemoteLoginUnavailableReason: String?
  let rss: InstanceRssCapability?
  let pushNotifications: InstancePushNotificationsCapability?

  private enum CodingKeys: String, CodingKey {
    case name
    case tagline
    case version
    case apiVersion
    case registrationAllowed
    case guestAllowed
    case supportedServices
    case logoURL = "logoUrl"
    case bannerURL = "bannerUrl"
    case localLoginEnabled
    case oidcEnabled
    case oidcProviderName
    case oidcAutoRedirect
    case youtubeRemoteLoginEnabled
    case youtubeRemoteLoginReady
    case youtubeRemoteLoginUnavailableReason
    case rss
    case pushNotifications
  }
}

struct InstanceRssCapability: Decodable, Equatable {
  let enabled: Bool
  let maxFeedsPerUser: Int?
}

struct InstancePushNotificationsCapability: Decodable, Equatable {
  let enabled: Bool
  let provider: String?
  let eventTypes: [String]?
  let maxDevicesPerAccount: Int?
}
