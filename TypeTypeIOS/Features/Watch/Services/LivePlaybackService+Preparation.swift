import Foundation

extension LivePlaybackService {
  func prepareYouTubeSABR(
    stream: LivePlaybackStream,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation {
    var videos = stream.allVideoSources.filter {
      $0.isSABR && $0.isAppleH264 && $0.itag > 0
    }
    var audios = stream.audioStreams.filter {
      $0.isSABR && $0.isAppleAAC && $0.itag > 0
    }
    if preferences.audioOnly {
      // In audio-only the video track is never decoded - its itag only
      // echoes through the SABR session contract - so any SABR video will
      // do when no H.264 one exists. Audio falls back to any SABR codec
      // only as a last resort: AAC is what the platform decodes reliably.
      if videos.isEmpty {
        videos = stream.allVideoSources.filter { $0.isSABR && $0.itag > 0 }
      }
      if audios.isEmpty {
        audios = stream.audioStreams.filter { $0.isSABR && $0.itag > 0 }
      }
    }
    let video = selectVideo(
      from: videos,
      quality: preferences.quality,
      preferredCodec: preferences.preferredCodec,
      requestedItag: preferences.videoItag
    )
    let audio = selectAudio(
      from: audios,
      requestedTrackID: preferences.audioTrackID
    )
    guard let video, let audio else {
      throw LivePlaybackFailure.noPlayableSource
    }
    return LivePlaybackPreparation(
      stream: stream,
      assetURL: nil,
      usesAuthenticatedLoader: true,
      video: video,
      audio: audio,
      providerPlayback: nil,
      subtitles: stream.subtitles,
      resumeTime: TimeInterval(max(stream.startPosition, 0)),
      isSABR: true,
      audioOnly: preferences.audioOnly
    )
  }

  func prepareProviderPlayback(
    stream: LivePlaybackStream,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation {
    if let hlsURL = serverResourceURL(for: stream.hlsURL) {
      let isServer = isSelectedServerURL(hlsURL)
      return LivePlaybackPreparation(
        stream: stream,
        assetURL: isServer ? authenticatedAssetURL(for: hlsURL) : hlsURL,
        usesAuthenticatedLoader: isServer,
        video: nil,
        audio: nil,
        providerPlayback: nil,
        subtitles: stream.subtitles,
        resumeTime: TimeInterval(max(stream.startPosition, 0)),
        isSABR: false,
        audioOnly: preferences.audioOnly
      )
    }
    let muxed = stream.videoStreams.filter {
      !$0.isVideoOnly && !$0.url.isEmpty
        && $0.mimeType.lowercased().hasPrefix("video/mp4")
    }
    if let selected = selectVideo(
      from: muxed,
      quality: preferences.quality,
      preferredCodec: preferences.preferredCodec,
      requestedItag: preferences.videoItag,
      requestedSourceID: preferences.videoSourceID
    ), let url = serverResourceURL(for: selected.url) {
      return LivePlaybackPreparation(
        stream: stream,
        assetURL: url,
        usesAuthenticatedLoader: false,
        video: selected,
        audio: nil,
        providerPlayback: nil,
        subtitles: stream.subtitles,
        resumeTime: TimeInterval(max(stream.startPosition, 0)),
        isSABR: false,
        audioOnly: preferences.audioOnly
      )
    }

    let videos = stream.allVideoSources.filter {
      !$0.isSABR && !$0.url.isEmpty && $0.isAppleProviderVideo
    }
    let audios = stream.audioStreams.filter {
      !$0.isSABR && !$0.url.isEmpty && $0.isAppleProviderAudio
    }
    guard let video = selectVideo(
      from: videos,
      quality: preferences.quality,
      preferredCodec: preferences.preferredCodec,
      requestedItag: preferences.videoItag,
      requestedSourceID: preferences.videoSourceID
    ), let audio = selectAudio(
      from: audios,
      requestedTrackID: preferences.audioTrackID,
      requestedSourceID: preferences.audioSourceID
    ), let videoURL = URL(string: video.url),
      let audioURL = URL(string: audio.url)
    else {
      throw LivePlaybackFailure.noPlayableSource
    }

    let videoMethod = providerDeliveryMethod(
      declared: video.deliveryMethod,
      sourceURL: videoURL
    )
    var audioMethod = providerDeliveryMethod(
      declared: audio.deliveryMethod,
      sourceURL: audioURL
    )
    // NicoNico labels its HLS audio "progressive" and its media URLs carry no
    // .m3u8 extension: audio without byte-range data next to HLS video is HLS.
    if videoMethod == "hls", audioMethod == "progressive",
      audio.initEnd == 0, audio.indexEnd == 0 {
      audioMethod = "hls"
    }
    let providerPlayback: LiveProviderPlayback
    let usesAuthenticatedLoader: Bool
    if videoMethod == "hls", audioMethod == "hls" {
      guard
        let proxiedVideo = providerProxyURL(
          for: videoURL,
          authenticated: true
        ),
        let proxiedAudio = providerProxyURL(
          for: audioURL,
          authenticated: true
        )
      else {
        throw LivePlaybackFailure.invalidServerResource
      }
      providerPlayback = .separateHLS(
        videoURL: proxiedVideo,
        audioURL: proxiedAudio
      )
      usesAuthenticatedLoader = true
    } else if videoMethod == "progressive",
      audioMethod == "progressive" {
      guard
        let preparedVideoURL = providerProxyURL(
          for: videoURL,
          authenticated: true
        ),
        let preparedAudioURL = providerProxyURL(
          for: audioURL,
          authenticated: true
        )
      else {
        throw LivePlaybackFailure.invalidServerResource
      }
      providerPlayback = .separateProgressive(
        videoURL: preparedVideoURL,
        audioURL: preparedAudioURL
      )
      usesAuthenticatedLoader = true
    } else {
      throw LivePlaybackFailure.noPlayableSource
    }

    return LivePlaybackPreparation(
      stream: stream,
      assetURL: nil,
      usesAuthenticatedLoader: usesAuthenticatedLoader,
      video: video,
      audio: audio,
      providerPlayback: providerPlayback,
      subtitles: stream.subtitles,
      resumeTime: TimeInterval(max(stream.startPosition, 0)),
      isSABR: false,
      audioOnly: preferences.audioOnly
    )
  }

}
