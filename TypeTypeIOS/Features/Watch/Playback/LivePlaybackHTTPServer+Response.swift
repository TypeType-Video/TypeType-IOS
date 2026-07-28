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
}
