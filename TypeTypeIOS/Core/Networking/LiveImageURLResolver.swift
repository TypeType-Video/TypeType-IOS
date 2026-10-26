import Foundation

/// Resolves the server's image references the way the Android client does
/// (`ProfileAvatar.kt`, `ShareUrls.buildImageUrl`): absolute URLs pass
/// through, root-relative paths join the instance base, everything else
/// resolves against it. Plain `URL(string:)` keeps such values relative and
/// `AsyncImage` never loads them — that is why the profile avatar showed
/// only the placeholder.
enum LiveImageURLResolver {
  /// Set once at startup with the active instance base URL.
  static var baseURLProvider: () -> URL? = { nil }

  static func resolve(_ reference: String?) -> URL? {
    guard var reference = reference?.trimmingCharacters(
      in: .whitespacesAndNewlines
    ), !reference.isEmpty
    else { return nil }
    // The server occasionally emits the `httpss://` typo that the Android
    // client corrects too.
    if reference.hasPrefix("httpss://") {
      reference = "https://" + reference.dropFirst("httpss://".count)
    }
    return resolve(URL(string: reference))
  }

  static func resolve(_ url: URL?) -> URL? {
    guard let url else { return nil }
    if url.scheme == "http" || url.scheme == "https" {
      return url
    }
    guard let base = baseURLProvider() else { return url }
    let baseString = base.absoluteString.hasSuffix("/")
      ? String(base.absoluteString.dropLast())
      : base.absoluteString
    let reference = url.absoluteString
    if reference.hasPrefix("/") {
      return URL(string: baseString + reference) ?? url
    }
    guard let root = URL(string: baseString + "/") else { return url }
    return URL(string: reference, relativeTo: root)?.absoluteURL ?? url
  }
}
