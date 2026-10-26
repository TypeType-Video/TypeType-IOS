import Foundation
import Network

extension LivePlaybackHTTPServer {
  func accept(_ connection: NWConnection) {
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

  func receive(
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

  func handle(_ data: Data, on connection: NWConnection) {
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
      } catch is CancellationError {
        send(
          status: 410,
          reason: "Gone",
          body: Data(),
          mimeType: "text/plain",
          on: connection
        )
      } catch {
        if isStaleSABRResourceFailure(error, route: route) {
          send(
            status: 410,
            reason: "Gone",
            body: Data(),
            mimeType: "text/plain",
            on: connection
          )
          return
        }
        if Self.isTransportFailure(error) {
          lock.withLock { lastTransportFailureAt = Date() }
        }
        let failure = error as NSError
        AppLogger.app.error(
          "Local playback response failed: \(failure.domain, privacy: .public) \(failure.code) \(failure.localizedDescription, privacy: .public)"
        )
        if let kind = providerMediaKind(for: route.target) {
          providerFailureHandler?(self, kind)
        }
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

  private func isStaleSABRResourceFailure(
    _ error: Error,
    route: Route
  ) -> Bool {
    guard case let .upstream(url) = route.target,
      url.scheme == LivePlaybackService.authenticatedScheme,
      url.path.contains("/sabr/playback/"),
      case let NetworkError.statusCode(code, message) = error,
      code == 409
    else {
      return false
    }
    return message?.localizedCaseInsensitiveContains(
      "stale SABR playback generation"
    ) == true
  }

  func remove(_ connection: NWConnection) {
    _ = lock.withLock {
      connections.removeValue(forKey: ObjectIdentifier(connection))
    }
  }
}
