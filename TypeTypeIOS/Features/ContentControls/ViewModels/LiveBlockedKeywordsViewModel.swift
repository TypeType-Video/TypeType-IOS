import Foundation

@MainActor
final class LiveBlockedKeywordsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var keywords: [LiveBlockedKeywordItem] = []
  @Published private(set) var isBusy = false
  @Published var keyword = ""
  @Published var errorMessage: String?

  private let service: LiveContentControlsServiceProtocol

  init(service: LiveContentControlsServiceProtocol) {
    self.service = service
  }

  var canAdd: Bool {
    !isBusy && !keyword.trimmingCharacters(in: .whitespaces).isEmpty
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      keywords = try await service.keywords()
      state = .loaded
    } catch {
      state = .failed(message(for: error))
    }
  }

  func add() async {
    let value = keyword.trimmingCharacters(in: .whitespaces)
    guard canAdd else { return }
    isBusy = true
    errorMessage = nil
    defer { isBusy = false }
    do {
      let item = try await service.addKeyword(value)
      guard !keywords.contains(where: { $0.keyword == item.keyword }) else {
        keyword = ""
        return
      }
      keywords.append(item)
      keywords.sort {
        $0.keyword.localizedCaseInsensitiveCompare($1.keyword)
          == .orderedAscending
      }
      keyword = ""
    } catch {
      errorMessage = message(for: error)
    }
  }

  func remove(_ item: LiveBlockedKeywordItem) async {
    isBusy = true
    errorMessage = nil
    defer { isBusy = false }
    do {
      try await service.removeKeyword(item.keyword)
      keywords.removeAll { $0.id == item.id }
    } catch {
      errorMessage = message(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Blocked keyword could not be updated."
  }
}
