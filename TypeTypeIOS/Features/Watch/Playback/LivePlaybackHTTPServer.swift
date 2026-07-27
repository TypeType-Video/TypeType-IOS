import Foundation
import Network

final class LivePlaybackHTTPServer: @unchecked Sendable {
  private struct Resource {
    let data: Data
    let mimeType: String
  }

  private enum Target {
    case upstream(URL)
    case subtitlePlaylist(Int)
    case subtitleVTT(Int)
  }

  private struct Route {
    let target: Target
    let pathExtension: String
  }

  private struct Request {
    let method: String
    let path: String
    let range: ClosedRange<Int>?
  }

  private let service: LivePlaybackServiceProtocol
  private let preparation: LivePlaybackPreparation
  private let preferredSubtitleLanguage: String
  private let queue = DispatchQueue(
    label: "dev.typetype.ios.live-playback-http",
    qos: .userInitiated
  )
  private let lock = NSLock()
  private let cache = NSCache<NSString, NSData>()
  private var listener: NWListener?
  private var connections: [ObjectIdentifier: NWConnection] = [:]
  private var routes: [String: Route] = [:]
  private var upstreamRouteIDs: [URL: String] = [:]
  private var localPort: NWEndpoint.Port?

  init(
    service: LivePlaybackServiceProtocol,
    preparation: LivePlaybackPreparation,
    preferredSubtitleLanguage: String
  ) {
    self.service = service
    self.preparation = preparation
    self.preferredSubtitleLanguage = preferredSubtitleLanguage
    cache.totalCostLimit = 128 * 1_024 * 1_024
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
    let routeID = register(
      target: .upstream(preparation.assetURL),
      pathExtension: "m3u8"
    )
    guard let url = localURL(routeID: routeID, extension: "m3u8") else {
      stop()
      throw LivePlaybackFailure.localPlaybackUnavailable
    }
    return url
  }

  func stop() {
    let active = lock.withLock { () -> [NWConnection] in
      let current = Array(connections.values)
      connections.removeAll()
      routes.removeAll()
      upstreamRouteIDs.removeAll()
      return current
    }
    active.forEach { $0.cancel() }
    listener?.cancel()
    listener = nil
    localPort = nil
    cache.removeAllObjects()
  }

  private func accept(_ connection: NWConnection) {
    let identifier = ObjectIdentifier(connection)
    lock.withLock {
      connections[identifier] = connection
    }
    connection.stateUpdateHandler = { [weak self, weak connection] state in
      guard let self, let connection else { return }
      switch state {
      case .failed, .cancelled:
        remove(connection)
      default:
        break
      }
    }
    connection.start(queue: queue)
    receive(on: connection, accumulated: Data())
  }

  private func receive(
    on connection: NWConnection,
    accumulated: Data
  ) {
    connection.receive(
      minimumIncompleteLength: 1,
      maximumLength: 64 * 1_024
    ) { [weak self, weak connection] data, _, isComplete, error in
      guard let self, let connection else { return }
      var buffer = accumulated
      if let data {
        buffer.append(data)
      }
      if let error {
        send(
          status: 400,
          reason: "Bad Request",
          body: Data(error.localizedDescription.utf8),
          mimeType: "text/plain; charset=utf-8",
          on: connection
        )
        return
      }
      if buffer.range(of: Data("\r\n\r\n".utf8)) != nil {
        handle(buffer, on: connection)
      } else if isComplete || buffer.count >= 64 * 1_024 {
        send(
          status: 400,
          reason: "Bad Request",
          body: Data(),
          mimeType: "text/plain",
          on: connection
        )
      } else {
        receive(on: connection, accumulated: buffer)
      }
    }
  }

  private func handle(_ data: Data, on connection: NWConnection) {
    guard let request = parseRequest(data) else {
      send(
        status: 400,
        reason: "Bad Request",
        body: Data(),
        mimeType: "text/plain",
        on: connection
      )
      return
    }
    guard request.method == "GET" || request.method == "HEAD" else {
      send(
        status: 405,
        reason: "Method Not Allowed",
        body: Data(),
        mimeType: "text/plain",
        on: connection
      )
      return
    }
    guard let route = route(for: request.path) else {
      send(
        status: 404,
        reason: "Not Found",
        body: Data(),
        mimeType: "text/plain",
        on: connection
      )
      return
    }
    Task { [weak self, weak connection] in
      guard let self, let connection else { return }
      do {
        let resource = try await load(route)
        send(
          resource,
          range: request.range,
          includeBody: request.method == "GET",
          on: connection
        )
      } catch {
        send(
          status: 502,
          reason: "Bad Gateway",
          body: Data(),
          mimeType: "text/plain",
          on: connection
        )
      }
    }
  }

  private func load(_ route: Route) async throws -> Resource {
    let cacheKey = cacheKey(for: route)
    if let cached = cache.object(forKey: cacheKey) {
      return Resource(
        data: cached as Data,
        mimeType: mimeType(for: route)
      )
    }

    let resource: Resource
    switch route.target {
    case let .upstream(url):
      let data = try await service.resourceData(for: url)
      if isPlaylist(data) {
        resource = Resource(
          data: try rewritePlaylist(data, upstreamURL: url),
          mimeType: Self.playlistMIME
        )
      } else {
        resource = Resource(
          data: data,
          mimeType: upstreamMIMEType(for: url)
        )
      }
    case let .subtitlePlaylist(index):
      guard preparation.subtitles.indices.contains(index) else {
        throw LivePlaybackFailure.invalidServerResource
      }
      resource = Resource(
        data: Data(subtitlePlaylist(index: index).utf8),
        mimeType: Self.playlistMIME
      )
    case let .subtitleVTT(index):
      guard preparation.subtitles.indices.contains(index) else {
        throw LivePlaybackFailure.invalidServerResource
      }
      let data = try await service.subtitleData(
        for: preparation.subtitles[index]
      )
      resource = Resource(
        data: normalizedVTT(data),
        mimeType: "text/vtt"
      )
    }
    cache.setObject(
      resource.data as NSData,
      forKey: cacheKey,
      cost: resource.data.count
    )
    return resource
  }

  private func rewritePlaylist(
    _ data: Data,
    upstreamURL: URL
  ) throws -> Data {
    guard let source = String(data: data, encoding: .utf8),
      source.hasPrefix("#EXTM3U")
    else {
      throw LivePlaybackFailure.invalidPlaylist
    }
    var lines = source.split(
      separator: "\n",
      omittingEmptySubsequences: false
    ).map(String.init)

    for index in lines.indices {
      if lines[index].hasPrefix("#") {
        lines[index] = try rewriteAttributeURLs(
          lines[index],
          relativeTo: upstreamURL
        )
      } else if !lines[index]
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .isEmpty {
        lines[index] = try localResourceString(
          lines[index],
          relativeTo: upstreamURL
        )
      }
    }

    if source.contains("#EXT-X-STREAM-INF"),
      !preparation.subtitles.isEmpty {
      let defaultIndex = preferredSubtitleIndex
      let declarations = preparation.subtitles.indices.compactMap {
        index -> String? in
        let routeID = register(
          target: .subtitlePlaylist(index),
          pathExtension: "m3u8"
        )
        guard let url = localURL(
          routeID: routeID,
          extension: "m3u8"
        ) else {
          return nil
        }
        let subtitle = preparation.subtitles[index]
        let isDefault = index == defaultIndex ? "YES" : "NO"
        return
          "#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"subs\","
          + "NAME=\"\(hlsQuoted(subtitle.displayName))\","
          + "LANGUAGE=\"\(hlsQuoted(subtitle.languageTag))\","
          + "AUTOSELECT=YES,DEFAULT=\(isDefault),FORCED=NO,"
          + "URI=\"\(url.absoluteString)\""
      }
      let insertion = lines.firstIndex {
        $0.hasPrefix("#EXT-X-STREAM-INF")
      } ?? lines.endIndex
      lines.insert(contentsOf: declarations, at: insertion)
      for index in lines.indices where lines[index].hasPrefix(
        "#EXT-X-STREAM-INF"
      ) {
        if !lines[index].contains("SUBTITLES=") {
          lines[index] += ",SUBTITLES=\"subs\""
        }
      }
    }
    return Data(lines.joined(separator: "\n").utf8)
  }

  private func rewriteAttributeURLs(
    _ line: String,
    relativeTo baseURL: URL
  ) throws -> String {
    let expression = try NSRegularExpression(
      pattern: #"URI="([^"]+)""#
    )
    var rewritten = line
    let matches = expression.matches(
      in: line,
      range: NSRange(line.startIndex..., in: line)
    )
    for match in matches.reversed() {
      guard let valueRange = Range(match.range(at: 1), in: rewritten) else {
        continue
      }
      let value = String(rewritten[valueRange])
      let replacement = try localResourceString(
        value,
        relativeTo: baseURL
      )
      rewritten.replaceSubrange(valueRange, with: replacement)
    }
    return rewritten
  }

  private func localResourceString(
    _ rawValue: String,
    relativeTo baseURL: URL
  ) throws -> String {
    let trimmed = rawValue.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard let upstream = URL(
      string: trimmed,
      relativeTo: baseURL
    )?.absoluteURL,
      upstream.scheme == "typetype-sabr"
    else {
      throw LivePlaybackFailure.invalidServerResource
    }
    let pathExtension = localExtension(for: upstream)
    let routeID = register(
      target: .upstream(upstream),
      pathExtension: pathExtension
    )
    guard let local = localURL(
      routeID: routeID,
      extension: pathExtension
    ) else {
      throw LivePlaybackFailure.localPlaybackUnavailable
    }
    return local.absoluteString
  }

  private func subtitlePlaylist(index: Int) -> String {
    let targetDuration = max(
      Int(ceil(TimeInterval(preparation.stream.duration))),
      1
    )
    let routeID = register(
      target: .subtitleVTT(index),
      pathExtension: "vtt"
    )
    let url = localURL(routeID: routeID, extension: "vtt")
    return """
      #EXTM3U
      #EXT-X-VERSION:7
      #EXT-X-TARGETDURATION:\(targetDuration)
      #EXT-X-MEDIA-SEQUENCE:0
      #EXT-X-PLAYLIST-TYPE:VOD
      #EXTINF:\(String(format: "%.3f", preparation.stream.duration)),
      \(url?.absoluteString ?? "")
      #EXT-X-ENDLIST

      """
  }

  private func normalizedVTT(_ data: Data) -> Data {
    guard var source = String(data: data, encoding: .utf8) else {
      return data
    }
    if !source.hasPrefix("WEBVTT") {
      source = "WEBVTT\n\n\(source)"
    }
    if !source.contains("X-TIMESTAMP-MAP") {
      let line = "X-TIMESTAMP-MAP=LOCAL:00:00:00.000,MPEGTS:0\n"
      if let marker = source.range(of: "\n") {
        source.insert(contentsOf: "\n\(line)", at: marker.upperBound)
      } else {
        source += "\n\n\(line)"
      }
    }
    return Data(source.utf8)
  }

  private func register(
    target: Target,
    pathExtension: String
  ) -> String {
    if case let .upstream(url) = target,
      let existing = lock.withLock({
        upstreamRouteIDs[url]
      }) {
      return existing
    }
    let identifier = UUID().uuidString.lowercased()
    lock.withLock {
      routes[identifier] = Route(
        target: target,
        pathExtension: pathExtension
      )
      if case let .upstream(url) = target {
        upstreamRouteIDs[url] = identifier
      }
    }
    return identifier
  }

  private func route(for path: String) -> Route? {
    guard path.hasPrefix("/resource/") else { return nil }
    let file = String(path.dropFirst("/resource/".count))
    let identifier = String(file.split(separator: ".").first ?? "")
    return lock.withLock { routes[identifier] }
  }

  private func localURL(
    routeID: String,
    extension pathExtension: String
  ) -> URL? {
    guard let port = localPort else { return nil }
    return URL(
      string: "http://127.0.0.1:\(port.rawValue)"
        + "/resource/\(routeID).\(pathExtension)"
    )
  }

  private func parseRequest(_ data: Data) -> Request? {
    guard let text = String(data: data, encoding: .utf8),
      let headersEnd = text.range(of: "\r\n\r\n")
    else {
      return nil
    }
    let headers = text[..<headersEnd.lowerBound]
      .split(separator: "\r\n", omittingEmptySubsequences: false)
      .map(String.init)
    guard let first = headers.first else { return nil }
    let requestParts = first.split(separator: " ")
    guard requestParts.count >= 2 else { return nil }
    let method = String(requestParts[0]).uppercased()
    let rawTarget = String(requestParts[1])
    let path: String
    if let absolute = URL(string: rawTarget),
      absolute.scheme != nil {
      path = absolute.path
    } else {
      path = rawTarget.split(separator: "?", maxSplits: 1)
        .first.map(String.init) ?? rawTarget
    }
    let rangeHeader = headers.dropFirst().first {
      $0.lowercased().hasPrefix("range:")
    }
    return Request(
      method: method,
      path: path,
      range: rangeHeader.flatMap(parseRange)
    )
  }

  private func parseRange(_ header: String) -> ClosedRange<Int>? {
    guard let value = header.split(
      separator: ":",
      maxSplits: 1
    ).last?.trimmingCharacters(in: .whitespaces),
      value.lowercased().hasPrefix("bytes=")
    else {
      return nil
    }
    let range = value.dropFirst("bytes=".count)
      .split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
    guard range.count == 2, let start = Int(range[0]) else {
      return nil
    }
    let end = Int(range[1]) ?? Int.max
    return start...max(start, end)
  }

  private func send(
    _ resource: Resource,
    range: ClosedRange<Int>?,
    includeBody: Bool,
    on connection: NWConnection
  ) {
    let total = resource.data.count
    if let range {
      guard range.lowerBound < total else {
        send(
          status: 416,
          reason: "Range Not Satisfiable",
          body: Data(),
          mimeType: resource.mimeType,
          additionalHeaders: [
            "Content-Range": "bytes */\(total)"
          ],
          on: connection
        )
        return
      }
      let upperBound = min(range.upperBound, total - 1)
      let body = includeBody
        ? resource.data[range.lowerBound...upperBound]
        : Data.SubSequence()
      send(
        status: 206,
        reason: "Partial Content",
        body: Data(body),
        mimeType: resource.mimeType,
        contentLength: upperBound - range.lowerBound + 1,
        additionalHeaders: [
          "Content-Range":
            "bytes \(range.lowerBound)-\(upperBound)/\(total)"
        ],
        on: connection
      )
    } else {
      send(
        status: 200,
        reason: "OK",
        body: includeBody ? resource.data : Data(),
        mimeType: resource.mimeType,
        contentLength: total,
        on: connection
      )
    }
  }

  private func send(
    status: Int,
    reason: String,
    body: Data,
    mimeType: String,
    contentLength: Int? = nil,
    additionalHeaders: [String: String] = [:],
    on connection: NWConnection
  ) {
    var headers = [
      "HTTP/1.1 \(status) \(reason)",
      "Content-Type: \(mimeType)",
      "Content-Length: \(contentLength ?? body.count)",
      "Accept-Ranges: bytes",
      "Cache-Control: no-store",
      "Connection: close",
    ]
    headers.append(contentsOf: additionalHeaders.map {
      "\($0.key): \($0.value)"
    })
    headers.append("")
    headers.append("")
    var response = Data(headers.joined(separator: "\r\n").utf8)
    response.append(body)
    connection.send(
      content: response,
      completion: .contentProcessed { [weak self, weak connection] _ in
        guard let self, let connection else { return }
        connection.cancel()
        remove(connection)
      }
    )
  }

  private func remove(_ connection: NWConnection) {
    _ = lock.withLock {
      connections.removeValue(forKey: ObjectIdentifier(connection))
    }
  }

  private func cacheKey(for route: Route) -> NSString {
    switch route.target {
    case let .upstream(url):
      return "upstream:\(url.absoluteString)" as NSString
    case let .subtitlePlaylist(index):
      return "subtitle-playlist:\(index)" as NSString
    case let .subtitleVTT(index):
      return "subtitle-vtt:\(index)" as NSString
    }
  }

  private func mimeType(for route: Route) -> String {
    switch route.target {
    case let .upstream(url):
      return upstreamMIMEType(for: url)
    case .subtitlePlaylist:
      return Self.playlistMIME
    case .subtitleVTT:
      return "text/vtt"
    }
  }

  private func upstreamMIMEType(for url: URL) -> String {
    if localExtension(for: url) == "m3u8" {
      return Self.playlistMIME
    }
    if let audioItag = preparation.audio?.itag,
      url.path.contains("/\(audioItag)/") {
      return "audio/mp4"
    }
    return "video/mp4"
  }

  private func localExtension(for url: URL) -> String {
    let query = URLComponents(
      url: url,
      resolvingAgainstBaseURL: false
    )?.queryItems ?? []
    if url.pathExtension.lowercased() == "m3u8"
      || query.contains(where: {
        $0.name == "format" && $0.value == "hls"
      })
      || query.contains(where: { $0.name == "playlist" }) {
      return "m3u8"
    }
    return "m4s"
  }

  private func isPlaylist(_ data: Data) -> Bool {
    guard data.count >= 7 else { return false }
    return String(
      data: data.prefix(7),
      encoding: .utf8
    ) == "#EXTM3U"
  }

  private var preferredSubtitleIndex: Int {
    guard !preferredSubtitleLanguage.isEmpty else { return 0 }
    return preparation.subtitles.firstIndex {
      $0.languageTag.caseInsensitiveCompare(
        preferredSubtitleLanguage
      ) == .orderedSame
        || $0.languageTag.lowercased().hasPrefix(
          preferredSubtitleLanguage.lowercased()
        )
    } ?? 0
  }

  private func hlsQuoted(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\r", with: " ")
  }

  private static let playlistMIME =
    "application/vnd.apple.mpegurl"
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
