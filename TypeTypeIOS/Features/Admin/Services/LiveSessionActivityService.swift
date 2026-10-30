import Foundation
import UIKit

@MainActor
protocol LiveSessionActivityServiceProtocol {
  func report() async throws
  func reportPlaybackStart(
    _ snapshot: LivePlaybackActivitySnapshot
  ) async throws
  func reportPlaybackProgress(
    _ snapshot: LivePlaybackActivitySnapshot
  ) async throws
  func reportPlaybackStop() async throws
  var deviceName: String { get }
  func setDeviceName(_ name: String)
}

final class LiveSessionActivityService:
  LiveSessionActivityServiceProtocol {
  private enum Storage {
    static let deviceID = "live.session-device-id"
    static let deviceName = "live.session-device-name"
  }

  private let apiClient: APIClient
  private let defaults: UserDefaults
  private let canReport: () -> Bool

  init(
    apiClient: APIClient,
    defaults: UserDefaults = .standard,
    canReport: @escaping () -> Bool = { true }
  ) {
    self.apiClient = apiClient
    self.defaults = defaults
    self.canReport = canReport
  }

  @MainActor
  func report() async throws {
    guard canReport() else { return }
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
  func reportPlaybackStart(
    _ snapshot: LivePlaybackActivitySnapshot
  ) async throws {
    try await reportPlayback(
      path: "/sessions/playback/start",
      snapshot: snapshot
    )
  }

  @MainActor
  func reportPlaybackProgress(
    _ snapshot: LivePlaybackActivitySnapshot
  ) async throws {
    try await reportPlayback(
      path: "/sessions/playback/progress",
      snapshot: snapshot
    )
  }

  @MainActor
  func reportPlaybackStop() async throws {
    guard canReport() else { return }
    try await apiClient.request(
      APIEndpoint(
        path: "/sessions/playback/stop",
        method: .post,
        body: try APIEndpoint.jsonBody(payload),
        requiresAuth: true
      )
    )
  }

  @MainActor
  private func reportPlayback(
    path: String,
    snapshot: LivePlaybackActivitySnapshot
  ) async throws {
    guard canReport() else { return }
    try await apiClient.request(
      APIEndpoint(
        path: path,
        method: .post,
        body: try APIEndpoint.jsonBody(
          LiveSessionPlaybackPayload(
            device: payload,
            snapshot: snapshot
          )
        ),
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
      deviceName: deviceName,
      deviceType: UIDevice.current.userInterfaceIdiom == .pad
        ? "tablet"
        : "mobile"
    )
  }

  var deviceName: String {
    let stored = defaults.string(forKey: Storage.deviceName) ?? ""
    return stored.isEmpty ? UIDevice.current.name : stored
  }

  func setDeviceName(_ name: String) {
    let trimmed = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
    if trimmed.isEmpty {
      defaults.removeObject(forKey: Storage.deviceName)
    } else {
      defaults.set(trimmed, forKey: Storage.deviceName)
    }
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

struct LivePlaybackActivitySnapshot: Equatable {
  let videoURL: String
  let title: String
  let thumbnailURL: String?
  let channelName: String?
  let positionMilliseconds: Int64
  let durationMilliseconds: Int64?
  let isPaused: Bool
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

private struct LiveSessionPlaybackPayload: Encodable {
  let clientName: String
  let clientVersion: String?
  let deviceID: String
  let deviceName: String
  let deviceType: String
  let videoURL: String
  let title: String
  let thumbnail: String?
  let channelName: String?
  let positionMilliseconds: Int64
  let durationMilliseconds: Int64?
  let paused: Bool

  init(
    device: LiveSessionActivityPayload,
    snapshot: LivePlaybackActivitySnapshot
  ) {
    clientName = device.clientName
    clientVersion = device.clientVersion
    deviceID = device.deviceID
    deviceName = device.deviceName
    deviceType = device.deviceType
    videoURL = snapshot.videoURL
    title = snapshot.title
    thumbnail = snapshot.thumbnailURL
    channelName = snapshot.channelName
    positionMilliseconds = snapshot.positionMilliseconds
    durationMilliseconds = snapshot.durationMilliseconds
    paused = snapshot.isPaused
  }

  private enum CodingKeys: String, CodingKey {
    case clientName, clientVersion
    case deviceID = "deviceId"
    case deviceName, deviceType
    case videoURL = "videoUrl"
    case title, thumbnail, channelName
    case positionMilliseconds = "positionMs"
    case durationMilliseconds = "durationMs"
    case paused
  }
}
