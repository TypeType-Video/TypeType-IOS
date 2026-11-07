import Foundation

extension LiveVideoItem {
  // The web client's rule: the server's flag, a "short" stream type, or a "shorts" segment in the address.
  var isShortForm: Bool {
    if isShortFormContent || streamType.lowercased().contains("short") { return true }
    return [id, url].contains { value in
      let path = URL(string: value)?.path ?? value
      return path.split(separator: "/").contains { $0.lowercased() == "shorts" }
    }
  }
}

extension Array where Element == LiveVideoItem {
  func hidingShorts(_ hide: Bool) -> [LiveVideoItem] {
    hide ? filter { !$0.isShortForm } : self
  }
}
