import Foundation

struct LiveOfflinePlaybackItem: Identifiable {
  let record: LiveManagedDownload
  let fileURL: URL

  var id: String {
    record.id
  }

  var isAudioOnly: Bool {
    record.options.mode.caseInsensitiveCompare("audio") == .orderedSame
  }
}
