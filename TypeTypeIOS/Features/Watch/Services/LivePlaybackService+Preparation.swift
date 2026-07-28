import Foundation

extension LivePlaybackService {
  func prepareYouTubeSABR(
    stream: LivePlaybackStream,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation {
    let videos = stream.allVideoSources.filter {
      $0.isSABR && $0.isAppleH264 && $0.itag > 0
    }
    let audios = stream.audioStreams.filter {
      $0.isSABR && $0.isAppleAAC && $0.itag > 0
    }
    let video = selectVideo(
      from: videos,
      quality: preferences.quality,
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
    if let hlsURL = URL(string: stream.hlsURL), !stream.hlsURL.isEmpty {
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
        audioOnly: false
      )
    }
    let muxed = stream.videoStreams.filter {
      !$0.isVideoOnly && !$0.url.isEmpty
        && $0.mimeType.lowercased().hasPrefix("video/mp4")
    }
    if let selected = selectVideo(
      from: muxed,
      quality: preferences.quality,
      requestedItag: preferences.videoItag,
      requestedSourceID: preferences.videoSourceID
    ), let url = URL(string: selected.url) {
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
        audioOnly: false
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
    let audioMethod = providerDeliveryMethod(
      declared: audio.deliveryMethod,
      sourceURL: audioURL
    )
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
      providerPlayback = .separateProgressive(
        videoURL: videoURL,
        audioURL: audioURL
      )
      usesAuthenticatedLoader = false
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
      audioOnly: false
    )
  }

}
