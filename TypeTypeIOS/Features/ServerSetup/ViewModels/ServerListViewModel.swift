import Combine
import Foundation

@MainActor
final class ServerListViewModel: ObservableObject {
  @Published var isPresentingConnectServer: Bool = false
  @Published var editingServer: ServerProfile?

  func openAddServerSheet() {
    isPresentingConnectServer = true
  }

  func closeAddServerSheet() {
    isPresentingConnectServer = false
  }

  func openEditServer(_ server: ServerProfile) {
    editingServer = server
  }

  func closeEditServer() {
    editingServer = nil
  }
}
