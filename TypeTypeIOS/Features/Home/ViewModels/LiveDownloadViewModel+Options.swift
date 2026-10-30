import Foundation

@MainActor
extension LiveDownloadViewModel {
  var options: LiveDownloadOptions {
    LiveDownloadOptions(
      mode: mode.rawValue,
      quality: quality,
      format: format,
      height: mode == .video ? selectedHeight : nil,
      videoCodec: mode == .video ? "h264" : nil,
      audioCodec: mode == .video || mode == .audio ? "aac" : nil,
      allowQualityFallback: true,
      sponsorBlock: false,
      sponsorBlockCategories: [],
      thumbnailOnly: mode == .thumbnail,
      subtitles: LiveDownloadSubtitleOptions(
        enabled: includesSubtitles,
        auto: includesSubtitles,
        embed: includesSubtitles && mode == .video,
        languages: subtitleLanguage.isEmpty ? [] : [subtitleLanguage],
        format: "srt"
      )
    )
  }

  private var selectedHeight: Int? {
    guard quality.hasSuffix("p") else { return nil }
    return Int(quality.dropLast())
  }
}
