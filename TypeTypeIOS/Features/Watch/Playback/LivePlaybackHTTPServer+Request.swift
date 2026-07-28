import Foundation

extension LivePlaybackHTTPServer {
  func parseRequest(_ data: Data) -> Request? {
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
}
