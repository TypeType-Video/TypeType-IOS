import AVFoundation
import Foundation

protocol LiveOfflineMediaValidating {
  func validate(
    fileURL: URL,
    mode: String
  ) async throws
}

struct LiveOfflineMediaValidator: LiveOfflineMediaValidating {
  private let fileManager: FileManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func validate(
    fileURL: URL,
    mode: String
  ) async throws {
    let attributes = try fileManager.attributesOfItem(
      atPath: fileURL.path
    )
    guard let size = attributes[.size] as? NSNumber,
      size.int64Value > 0
    else {
      throw LiveOfflineMediaValidationError.emptyFile
    }
    guard mode != LiveDownloadMode.thumbnail.rawValue else {
      return
    }
    let asset = AVURLAsset(url: fileURL)
    guard try await asset.load(.isPlayable) else {
      throw LiveOfflineMediaValidationError.unplayableMedia
    }
    if mode == LiveDownloadMode.audio.rawValue {
      let tracks = try await asset.loadTracks(
        withMediaType: .audio
      )
      guard !tracks.isEmpty else {
        throw LiveOfflineMediaValidationError.missingAudioTrack
      }
    } else if mode == LiveDownloadMode.video.rawValue {
      let tracks = try await asset.loadTracks(
        withMediaType: .video
      )
      guard !tracks.isEmpty else {
        throw LiveOfflineMediaValidationError.missingVideoTrack
      }
    }
  }
}

enum LiveOfflineMediaValidationError: LocalizedError {
  case emptyFile
  case unplayableMedia
  case missingAudioTrack
  case missingVideoTrack

  var errorDescription: String? {
    switch self {
    case .emptyFile:
      return "The downloaded file is empty."
    case .unplayableMedia:
      return "The downloaded media is not playable on this device."
    case .missingAudioTrack:
      return "The downloaded file does not contain an audio track."
    case .missingVideoTrack:
      return "The downloaded file does not contain a video track."
    }
  }
}
