import Foundation
import UIKit

@MainActor
protocol LiveSessionActivityServiceProtocol {
  func report() async throws
}

final class LiveSessionActivityService:
  LiveSessionActivityServiceProtocol {
  private enum Storage {
    static let deviceID = "live.session-device-id"
  }

  private let apiClient: APIClient
  private let defaults: UserDefaults

  init(
    apiClient: APIClient,
    defaults: UserDefaults = .standard
  ) {
    self.apiClient = apiClient
    self.defaults = defaults
  }

  @MainActor
  func report() async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/sessions/activity",
        method: .post,
        body: try APIEndpoint.jsonBody(payload),
        requiresAuth: true
      )
    )
  }

  @MainActor
  private var payload: LiveSessionActivityPayload {
    LiveSessionActivityPayload(
      clientName: "TypeType iOS",
      clientVersion: Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
      ) as? String,
      deviceID: stableDeviceID,
      deviceName: UIDevice.current.name,
      deviceType: UIDevice.current.userInterfaceIdiom == .pad
        ? "tablet"
        : "mobile"
    )
  }

  private var stableDeviceID: String {
    if let current = defaults.string(forKey: Storage.deviceID),
      !current.isEmpty {
      return current
    }
    let value = UUID().uuidString.lowercased()
    defaults.set(value, forKey: Storage.deviceID)
    return value
  }
}

private struct LiveSessionActivityPayload: Encodable {
  let clientName: String
  let clientVersion: String?
  let deviceID: String
  let deviceName: String
  let deviceType: String

  private enum CodingKeys: String, CodingKey {
    case clientName, clientVersion
    case deviceID = "deviceId"
    case deviceName, deviceType
  }
}
