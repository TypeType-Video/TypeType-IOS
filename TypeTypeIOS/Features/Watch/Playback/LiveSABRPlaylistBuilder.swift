import Foundation

enum LiveSABRPlaylistBuilder {
  static func master(
    preparation: LivePlaybackPreparation,
    snapshot: LiveSABRPlaybackSnapshot,
    audioURL: URL,
    videoURL: URL?
  ) -> Data {
    let activeAudio = preparation.stream.audioStreams.first {
      $0.itag == snapshot.audio.itag
    } ?? preparation.audio
    let activeVideo = snapshot.video.flatMap { track in
      preparation.stream.allVideoSources.first {
        $0.itag == track.itag
      }
    } ?? preparation.video
    guard !preparation.audioOnly, let videoURL,
      let video = activeVideo,
      let audio = activeAudio
    else {
      // HLS CODECS needs a full codec string ("mp4a.40.2"): a bare name makes AVPlayer reject the playlist.
      let rawCodec = activeAudio?.codec ?? ""
      let codec = rawCodec.contains(".") ? rawCodec : "mp4a.40.2"
      return data(
        """
        #EXTM3U
        #EXT-X-VERSION:7
        #EXT-X-INDEPENDENT-SEGMENTS
        #EXT-X-STREAM-INF:BANDWIDTH=\(audioBandwidth(activeAudio)),CODECS="\(codec)"
        \(audioURL.absoluteString)
        """
      )
    }
    let codecs = [video.codec, audio.codec]
      .compactMap { $0 }
      .joined(separator: ",")
    var attributes = [
      "BANDWIDTH=\(videoBandwidth(video) + audioBandwidth(audio))",
      "CODECS=\"\(codecs)\"",
      "AUDIO=\"audio\"",
    ]
    if video.width > 0, video.height > 0 {
      attributes.append("RESOLUTION=\(video.width)x\(video.height)")
    }
    if video.fps > 0 {
      attributes.append("FRAME-RATE=\(video.fps)")
    }
    return data(
      """
      #EXTM3U
      #EXT-X-VERSION:7
      #EXT-X-INDEPENDENT-SEGMENTS
      #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="\(audioName(audio))",DEFAULT=YES,AUTOSELECT=YES,URI="\(audioURL.absoluteString)"
      #EXT-X-STREAM-INF:\(attributes.joined(separator: ","))
      \(videoURL.absoluteString)
      """
    )
  }

  static func media(
    track: LiveSABRTrackSnapshot,
    snapshot: LiveSABRPlaybackSnapshot,
    kind: LiveSABRTrackKind
  ) throws -> Data {
    if snapshot.isIndexedVOD {
      return try vodMedia(
        track: track,
        snapshot: snapshot,
        kind: kind
      )
    }
    let slidingLive = snapshot.live?.active == true
      || (
        snapshot.index?.live == true
          && !snapshot.endOfStream
      )
    return eventMedia(
      track: track,
      endOfStream: snapshot.endOfStream,
      slidingLive: slidingLive
    )
  }

  private static func eventMedia(
    track: LiveSABRTrackSnapshot,
    endOfStream: Bool,
    slidingLive: Bool
  ) -> Data {
    let segments = track.segments
    let targetDuration = max(
      Int(ceil(Double(segments.map(\.durationMS).max() ?? 1) / 1_000)),
      1
    )
    let mediaSequence = segments.first?.sequence ?? 0
    var lines = [
      "#EXTM3U",
      "#EXT-X-VERSION:7",
      "#EXT-X-TARGETDURATION:\(targetDuration)",
      "#EXT-X-MEDIA-SEQUENCE:\(mediaSequence)",
    ]
    if !slidingLive {
      lines.append("#EXT-X-PLAYLIST-TYPE:EVENT")
    }
    lines.append(
      "#EXT-X-MAP:URI=\"\(track.initURL.absoluteString)\""
    )
    for segment in segments {
      let duration = String(
        format: "%.3f",
        Double(segment.durationMS) / 1_000
      )
      lines.append("#EXTINF:\(duration),")
      lines.append(segment.url.absoluteString)
    }
    if endOfStream {
      lines.append("#EXT-X-ENDLIST")
    }
    return data(lines.joined(separator: "\n"))
  }

  private static func vodMedia(
    track: LiveSABRTrackSnapshot,
    snapshot: LiveSABRPlaybackSnapshot,
    kind: LiveSABRTrackKind
  ) throws -> Data {
    guard let index = snapshot.index else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let endSequence: Int64 = switch kind {
    case .audio: index.tracks.audio.endSegment
    case .video: index.tracks.video.endSegment
    }
    guard endSequence > 0, endSequence <= Int64(Int.max),
      snapshot.durationMS > 0
    else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let count = Int(endSequence)
    let durations = vodDurations(
      track: track,
      count: count,
      durationMS: snapshot.durationMS
    )
    let targetDuration = max(
      Int(ceil(Double(durations.max() ?? 1) / 1_000)),
      1
    )
    var lines = [
      "#EXTM3U",
      "#EXT-X-VERSION:7",
      "#EXT-X-TARGETDURATION:\(targetDuration)",
      "#EXT-X-MEDIA-SEQUENCE:1",
      "#EXT-X-PLAYLIST-TYPE:VOD",
      "#EXT-X-START:TIME-OFFSET=\(startOffset(snapshot)),PRECISE=YES",
      "#EXT-X-MAP:URI=\"\(track.initURL.absoluteString)\"",
    ]
    for sequence in 1...count {
      guard let url = track.mediaURL(sequence: sequence) else {
        throw LivePlaybackFailure.invalidSABRContract
      }
      let duration = String(
        format: "%.3f",
        Double(durations[sequence - 1]) / 1_000
      )
      lines.append("#EXTINF:\(duration),")
      lines.append(url.absoluteString)
    }
    lines.append("#EXT-X-ENDLIST")
    return data(lines.joined(separator: "\n"))
  }

  private static func vodDurations(
    track: LiveSABRTrackSnapshot,
    count: Int,
    durationMS: Int64
  ) -> [Int64] {
    let known = track.segments.reduce(into: [Int: Int64]()) {
      values, segment in
      let sequence = segment.sequence
      guard (1...count).contains(sequence) else { return }
      values[sequence] = max(segment.durationMS, 1)
    }
    let knownTotal = known.values.reduce(Int64.zero, +)
    let unknownCount = max(count - known.count, 0)
    guard unknownCount > 0,
      knownTotal < durationMS
    else {
      let average = max(durationMS / Int64(count), 1)
      return Array(repeating: average, count: count)
    }
    let unknownDuration = max(
      (durationMS - knownTotal) / Int64(unknownCount),
      1
    )
    var values = (1...count).map { known[$0] ?? unknownDuration }
    let correction = durationMS - values.reduce(Int64.zero, +)
    values[count - 1] = max(values[count - 1] + correction, 1)
    return values
  }

  private static func startOffset(
    _ snapshot: LiveSABRPlaybackSnapshot
  ) -> String {
    String(
      format: "%.3f",
      Double(max(snapshot.startTimeMS, 0)) / 1_000
    )
  }

  private static func audioName(
    _ audio: LivePlaybackAudioSource
  ) -> String {
    audio.displayName
      .replacingOccurrences(of: "\"", with: "'")
      .replacingOccurrences(of: "\n", with: " ")
  }
  private static func videoBandwidth(
    _ video: LivePlaybackVideoSource?
  ) -> Int {
    max(video?.bitrate ?? 2_000_000, 1)
  }

  private static func audioBandwidth(
    _ audio: LivePlaybackAudioSource?
  ) -> Int {
    max(audio?.bitrate ?? 128_000, 1)
  }

  private static func data(_ source: String) -> Data {
    Data("\(source)\n".utf8)
  }
}
