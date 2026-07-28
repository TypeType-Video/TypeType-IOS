import Foundation

extension LivePlaybackHTTPServer {
  func rewritePlaylist(
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
      insertSubtitleDeclarations(in: &lines)
    }
    return Data(lines.joined(separator: "\n").utf8)
  }

  private func insertSubtitleDeclarations(in lines: inout [String]) {
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
    )?.absoluteURL
    else {
      throw LivePlaybackFailure.invalidServerResource
    }
    if isLocalURL(upstream) {
      return upstream.absoluteString
    }
    guard upstream.scheme == "typetype-sabr" else {
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
}
