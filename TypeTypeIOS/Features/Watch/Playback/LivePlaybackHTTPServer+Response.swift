import Foundation
import Network

extension LivePlaybackHTTPServer {
  func send(
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
      let body: Data = includeBody
        ? resource.data[range.lowerBound...upperBound]
        : Data()
      send(
        status: 206,
        reason: "Partial Content",
        body: body,
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

  func send(
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
    let headerData = Data(headers.joined(separator: "\r\n").utf8)
    connection.send(
      content: headerData,
      completion: .contentProcessed { [weak self, weak connection] error in
        guard let self, let connection else { return }
        guard error == nil else {
          abortResponse(on: connection)
          return
        }
        guard !body.isEmpty else {
          finishResponse(on: connection)
          return
        }
        connection.send(
          content: body,
          completion: .contentProcessed {
            [weak self, weak connection] error in
            guard let self, let connection else { return }
            guard error == nil else {
              abortResponse(on: connection)
              return
            }
            finishResponse(on: connection)
          }
        )
      }
    )
  }

  private func finishResponse(on connection: NWConnection) {
    connection.send(
      content: nil,
      contentContext: .finalMessage,
      isComplete: true,
      completion: .contentProcessed {
        [weak self, weak connection] error in
        guard let self, let connection else { return }
        guard error == nil else {
          abortResponse(on: connection)
          return
        }
        awaitPeerClose(on: connection)
      }
    )
  }

  private func awaitPeerClose(on connection: NWConnection) {
    connection.receive(
      minimumIncompleteLength: 1,
      maximumLength: 1_024
    ) { [weak self, weak connection] _, _, isComplete, error in
      guard let self, let connection else { return }
      if isComplete || error != nil {
        connection.cancel()
        remove(connection)
      } else {
        awaitPeerClose(on: connection)
      }
    }
    queue.asyncAfter(deadline: .now() + 2) {
      [weak self, weak connection] in
      guard let self, let connection,
        lock.withLock({
          self.connections[ObjectIdentifier(connection)] != nil
        })
      else {
        return
      }
      connection.cancel()
      remove(connection)
    }
  }

  private func abortResponse(on connection: NWConnection) {
    connection.cancel()
    remove(connection)
  }
}
