import Foundation

struct LiveVersionUnavailableService: LiveVersionServiceProtocol {
  struct Unavailable: LocalizedError {
    var errorDescription: String {
      "Version information is unavailable in this context."
    }
  }

  func fetchVersions() async throws -> LiveComponentVersions {
    throw Unavailable()
  }
}
