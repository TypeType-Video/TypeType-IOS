import Foundation

extension LiveSettings {
  static let holdPlaybackSpeeds: [Double] = [1.5, 2, 2.5, 3, 4]

  var holdSpeed: Double {
    Self.holdPlaybackSpeeds.first { $0 == holdPlaybackSpeed } ?? 2
  }

  var startsWhenOpened: Bool { autoplayOnOpen ?? true }

  var hidesUpcomingPlaylistVideos: Bool { hideUpcomingPlaylistVideos ?? false }
}
