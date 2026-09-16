import Foundation
import Network

final class LiveInterruptingProxy {
  private struct Pair {
    let client: NWConnection
    let upstream: NWConnection
  }

  private let upstreamHost: NWEndpoint.Host
  private let upstreamPort: NWEndpoint.Port
  private let queue = DispatchQueue(
    label: "dev.typetype.ios.tests.interrupting-proxy"
  )
  private var listener: NWListener?
  private var pairs: [UUID: Pair] = [:]
  private var offlineUntil = Date.distantPast

  init(
    upstreamHost: String = ProcessInfo.processInfo
      .environment["TYPETYPE_LIVE_UPSTREAM_HOST"]
      ?? "watch.typetype.video",
    upstreamPort: UInt16 = 443
  ) {
    self.upstreamHost = NWEndpoint.Host(upstreamHost)
    self.upstreamPort = NWEndpoint.Port(
      rawValue: upstreamPort
    )!
  }

  func start() throws -> URL {
    let listener = try NWListener(using: .tcp, on: .any)
    listener.parameters.requiredLocalEndpoint = .hostPort(
      host: "127.0.0.1",
      port: .any
    )
    self.listener = listener
    let ready = DispatchSemaphore(value: 0)
    var startupError: Error?
    listener.stateUpdateHandler = { state in
      switch state {
      case .ready:
        ready.signal()
      case let .failed(error):
        startupError = error
        ready.signal()
      default:
        break
      }
    }
    listener.newConnectionHandler = { [weak self] connection in
      self?.accept(connection)
    }
    listener.start(queue: queue)
    guard ready.wait(timeout: .now() + 5) == .success,
      startupError == nil,
      let port = listener.port,
      let url = URL(
        string: "http://127.0.0.1:\(port.rawValue)"
      )
    else {
      listener.cancel()
      throw startupError ?? LiveInterruptingProxyError.startFailed
    }
    return url
  }

  func stop() {
    queue.sync {
      listener?.cancel()
      listener = nil
      let active = pairs
      pairs.removeAll()
      active.values.forEach {
        $0.client.cancel()
        $0.upstream.cancel()
      }
    }
  }

  func cutTransport(for seconds: Int) {
    queue.sync {
      offlineUntil = Date().addingTimeInterval(
        TimeInterval(min(max(seconds, 1), 120))
      )
      let active = Array(pairs.keys)
      active.forEach { close($0, force: true) }
    }
  }

  private func accept(_ client: NWConnection) {
    client.start(queue: queue)
    receiveHeader(from: client, accumulated: Data())
  }

  private func receiveHeader(
    from client: NWConnection,
    accumulated: Data
  ) {
    client.receive(
      minimumIncompleteLength: 1,
      maximumLength: 64 * 1_024
    ) { [weak self, weak client] data, _, isComplete, error in
      guard let self, let client else { return }
      var request = accumulated
      if let data {
        request.append(data)
      }
      if error != nil || isComplete || request.count > 256 * 1_024 {
        client.forceCancel()
        return
      }
      guard let headerRange = request.range(
        of: Data("\r\n\r\n".utf8)
      ) else {
        receiveHeader(from: client, accumulated: request)
        return
      }
      let header = request.subdata(in: 0..<headerRange.upperBound)
      guard let source = String(data: header, encoding: .utf8) else {
        client.forceCancel()
        return
      }
      guard Date() >= offlineUntil,
        let forwarded = rewrittenRequest(
          source,
          remainder: request.subdata(
            in: headerRange.upperBound..<request.endIndex
          )
        )
      else {
        client.forceCancel()
        return
      }
      connect(client: client, initialRequest: forwarded)
    }
  }

  private func connect(
    client: NWConnection,
    initialRequest: Data
  ) {
    let upstream = NWConnection(
      host: upstreamHost,
      port: upstreamPort,
      using: .tls
    )
    let id = UUID()
    pairs[id] = Pair(client: client, upstream: upstream)
    upstream.stateUpdateHandler = {
      [weak self, weak upstream] state in
      guard let self, let upstream else { return }
      switch state {
      case .ready:
        guard Date() >= offlineUntil else {
          close(id, force: true)
          return
        }
        pump(from: upstream, to: client, id: id)
        upstream.send(
          content: initialRequest,
          completion: .contentProcessed { [weak self] error in
            guard let self else { return }
            guard error == nil else {
              close(id, force: true)
              return
            }
            pump(from: client, to: upstream, id: id)
          }
        )
      case .failed, .cancelled:
        close(id, force: false)
      default:
        break
      }
    }
    upstream.start(queue: queue)
  }

  private func pump(
    from source: NWConnection,
    to destination: NWConnection,
    id: UUID
  ) {
    source.receive(
      minimumIncompleteLength: 1,
      maximumLength: 64 * 1_024
    ) { [weak self, weak source, weak destination]
      data, _, isComplete, error in
      guard let self, let source, let destination,
        pairs[id] != nil
      else {
        return
      }
      guard error == nil else {
        close(id, force: true)
        return
      }
      if let data, !data.isEmpty {
        destination.send(
          content: data,
          completion: .contentProcessed { [weak self] sendError in
            guard let self else { return }
            guard sendError == nil else {
              close(id, force: true)
              return
            }
            if isComplete {
              finish(destination: destination, id: id)
            } else {
              pump(from: source, to: destination, id: id)
            }
          }
        )
      } else if isComplete {
        finish(destination: destination, id: id)
      } else {
        pump(from: source, to: destination, id: id)
      }
    }
  }

  private func finish(
    destination: NWConnection,
    id: UUID
  ) {
    destination.send(
      content: nil,
      contentContext: .finalMessage,
      isComplete: true,
      completion: .contentProcessed { [weak self] _ in
        self?.close(id, force: false)
      }
    )
  }

  private func rewrittenRequest(
    _ source: String,
    remainder: Data
  ) -> Data? {
    var lines = source.components(separatedBy: "\r\n")
    guard !lines.isEmpty else { return nil }
    var replacedHost = false
    lines = lines.compactMap { line in
      let lowercased = line.lowercased()
      if lowercased.hasPrefix("host:") {
        replacedHost = true
        return "Host: \(upstreamHost)"
      }
      if lowercased.hasPrefix("connection:") {
        return "Connection: close"
      }
      return line
    }
    if !replacedHost {
      lines.insert("Host: \(upstreamHost)", at: min(1, lines.count))
    }
    var request = Data(lines.joined(separator: "\r\n").utf8)
    request.append(remainder)
    return request
  }

  private func close(_ id: UUID, force: Bool) {
    guard let pair = pairs.removeValue(forKey: id) else { return }
    if force {
      pair.client.forceCancel()
      pair.upstream.forceCancel()
    } else {
      pair.client.cancel()
      pair.upstream.cancel()
    }
  }

}

private enum LiveInterruptingProxyError: Error {
  case startFailed
}
