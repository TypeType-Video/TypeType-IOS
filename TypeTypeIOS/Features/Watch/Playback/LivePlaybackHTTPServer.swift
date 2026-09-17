import Foundation
import Network

final class LivePlaybackHTTPServer: @unchecked Sendable {
  enum ProviderMediaKind: Sendable {
    case video
    case audio
  }

  typealias ProviderFailureHandler = @Sendable (
    LivePlaybackHTTPServer,
    ProviderMediaKind
  ) -> Void

  typealias SABRFailureHandler = @Sendable (Error) -> Void

  struct Resource: Sendable {
    let data: Data
    let mimeType: String
  }

  enum Target: Sendable {
    case upstream(URL)
    case upstreamRange(URL, ClosedRange<Int>, String)
    case sabrMaster
    case sabrTrack(LiveSABRTrackKind)
    case providerMaster
    case providerProgressiveVideo
    case providerProgressiveAudio
    case subtitlePlaylist(Int)
    case subtitleVTT(Int)
  }

  struct Route: Sendable {
    let target: Target
    let pathExtension: String
  }

  struct Request {
    let method: String
    let path: String
    let range: ClosedRange<Int>?
  }

  let service: LivePlaybackServiceProtocol
  let preparation: LivePlaybackPreparation
  let preferredSubtitleLanguage: String
  let providerFailureHandler: ProviderFailureHandler?
  let sabrFailureHandler: SABRFailureHandler?
  let queue = DispatchQueue(
    label: "dev.typetype.ios.live-playback-http",
    qos: .userInitiated
  )
  let lock = NSLock()
  let cache = NSCache<NSString, NSData>()
  let loadCoordinator = LivePlaybackResourceLoadCoordinator()
  var listener: NWListener?
  var connections: [ObjectIdentifier: NWConnection] = [:]
  var routes: [String: Route] = [:]
  var upstreamRouteIDs: [URL: String] = [:]
  var upstreamMediaRouteOrder: [URL] = []
  var localPort: NWEndpoint.Port?
  var sabrSession: LiveSABRPlaybackSession?
  var sabrMasterRouteID: String?
  var sabrAudioRouteID: String?
  var sabrVideoRouteID: String?
  var sabrMasterBaseURL: URL?
  var sabrPlaybackStartTime: TimeInterval = 0
  var providerProgressiveMaster: String?
  var providerProgressiveVideo: String?
  var providerProgressiveAudio: String?

  init(
    service: LivePlaybackServiceProtocol,
    preparation: LivePlaybackPreparation,
    preferredSubtitleLanguage: String,
    providerFailureHandler: ProviderFailureHandler? = nil,
    sabrFailureHandler: SABRFailureHandler? = nil
  ) {
    self.service = service
    self.preparation = preparation
    self.preferredSubtitleLanguage = preferredSubtitleLanguage
    self.providerFailureHandler = providerFailureHandler
    self.sabrFailureHandler = sabrFailureHandler
    cache.totalCostLimit = 128 * 1_024 * 1_024
  }

  func providerMediaKind(
    for target: Target
  ) -> ProviderMediaKind? {
    guard let providerPlayback = preparation.providerPlayback else {
      return nil
    }
    let targetURL: URL
    switch target {
    case let .upstream(url),
      let .upstreamRange(url, _, _):
      targetURL = url
    default:
      return nil
    }
    switch providerPlayback {
    case let .separateProgressive(videoURL, audioURL),
      let .separateHLS(videoURL, audioURL):
      if targetURL == videoURL {
        return .video
      }
      if targetURL == audioURL {
        return .audio
      }
      return nil
    }
  }

  func start() async throws -> URL {
    let listener = try NWListener(using: .tcp, on: .any)
    listener.parameters.requiredLocalEndpoint = .hostPort(
      host: "127.0.0.1",
      port: .any
    )
    listener.newConnectionHandler = { [weak self] connection in
      self?.accept(connection)
    }
    self.listener = listener

    let port = try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<NWEndpoint.Port, Error>) in
      let gate = ContinuationGate()
      listener.stateUpdateHandler = { state in
        switch state {
        case .ready:
          guard let port = listener.port else {
            gate.resume(
              continuation,
              throwing: LivePlaybackFailure.localPlaybackUnavailable
            )
            return
          }
          gate.resume(continuation, returning: port)
        case let .failed(error):
          gate.resume(continuation, throwing: error)
        case .cancelled:
          gate.resume(
            continuation,
            throwing: LivePlaybackFailure.localPlaybackUnavailable
          )
        default:
          break
        }
      }
      listener.start(queue: queue)
    }
    localPort = port
    let routeID: String
    if preparation.isSABR {
      routeID = try await startSABRSession()
    } else if let providerPlayback = preparation.providerPlayback {
      switch providerPlayback {
      case .separateHLS:
        routeID = register(
          target: .providerMaster,
          pathExtension: "m3u8"
        )
      case .separateProgressive:
        routeID = try await startProgressiveProviderSession()
      }
    } else {
      guard let assetURL = preparation.assetURL else {
        stop()
        throw LivePlaybackFailure.invalidServerResource
      }
      routeID = register(
        target: .upstream(assetURL),
        pathExtension: "m3u8"
      )
    }
    guard let url = localURL(routeID: routeID, extension: "m3u8") else {
      stop()
      throw LivePlaybackFailure.localPlaybackUnavailable
    }
    return url
  }

  func stop() {
    let activeSABRSession = sabrSession
    let active = lock.withLock { () -> [NWConnection] in
      let current = Array(connections.values)
      connections.removeAll()
      routes.removeAll()
      upstreamRouteIDs.removeAll()
      upstreamMediaRouteOrder.removeAll()
      return current
    }
    active.forEach { $0.cancel() }
    listener?.cancel()
    listener = nil
    localPort = nil
    sabrSession = nil
    if let activeSABRSession {
      Task {
        await activeSABRSession.stopMaintenance()
        await activeSABRSession.cancelWindowLoad()
      }
    }
    sabrMasterRouteID = nil
    sabrAudioRouteID = nil
    sabrVideoRouteID = nil
    sabrMasterBaseURL = nil
    sabrPlaybackStartTime = 0
    providerProgressiveMaster = nil
    providerProgressiveVideo = nil
    providerProgressiveAudio = nil
    cache.removeAllObjects()
    loadCoordinator.cancelAll()
  }

  func updatePlayerTime(_ seconds: TimeInterval) {
    guard let sabrSession else { return }
    Task {
      await sabrSession.updatePlayerTime(seconds)
    }
  }

  func updatePlaybackRate(_ rate: Float) {
    guard let sabrSession else { return }
    Task {
      await sabrSession.updatePlaybackRate(rate)
    }
  }

  func seekSABR(to seconds: TimeInterval) async throws -> URL {
    guard let sabrSession,
      let sabrMasterRouteID,
      let url = localURL(
        routeID: sabrMasterRouteID,
        extension: "m3u8"
      )
    else {
      throw LivePlaybackFailure.localPlaybackUnavailable
    }
    let snapshot = try await sabrSession.seek(to: seconds)
    discardStaleSABRResourceRoutes()
    sabrMasterBaseURL = snapshot.audio.initURL
    sabrPlaybackStartTime = snapshot.isIndexedVOD
      ? 0
      : TimeInterval(snapshot.startTimeMS) / 1_000
    cache.removeObject(forKey: "sabr-master")
    return url
  }

  static let playlistMIME = "application/vnd.apple.mpegurl"
  static let maximumUpstreamMediaRoutes = 1_024
}

private final class ContinuationGate: @unchecked Sendable {
  private let lock = NSLock()
  private var didResume = false

  func resume<T>(
    _ continuation: CheckedContinuation<T, Error>,
    returning value: T
  ) {
    guard lock.withLock({
      guard !didResume else { return false }
      didResume = true
      return true
    }) else {
      return
    }
    continuation.resume(returning: value)
  }

  func resume<T>(
    _ continuation: CheckedContinuation<T, Error>,
    throwing error: Error
  ) {
    guard lock.withLock({
      guard !didResume else { return false }
      didResume = true
      return true
    }) else {
      return
    }
    continuation.resume(throwing: error)
  }
}
