import Combine
import Foundation

@MainActor
final class ServerSetupViewModel: ObservableObject {
  @Published var name = ""
  @Published var url = ""
  @Published var isConnecting = false
  @Published var errorMessage: String?

  var canConnect: Bool {
    !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !isConnecting
  }

  func connect(using coordinator: RootCoordinator) async {
    guard canConnect else { return }
    isConnecting = true
    errorMessage = nil
    do {
      try await coordinator.addServer(
        name: name,
        urlInput: url
      )
      name = ""
      url = ""
    } catch {
      errorMessage = error.localizedDescription
    }
    isConnecting = false
  }

  func clearError() {
    errorMessage = nil
  }
}
