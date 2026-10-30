import Foundation

@MainActor
final class LiveNativeControlsState: ObservableObject {
  @Published var visible = true
  private var hideTask: Task<Void, Never>?
  private var tapTask: Task<Void, Never>?

  func tap() {
    tapTask?.cancel()
    tapTask = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(260))
      guard !Task.isCancelled, let self else { return }
      visible.toggle()
      if visible { scheduleHide() }
    }
  }

  func cancelTap() {
    tapTask?.cancel()
  }

  func keepVisible() {
    hideTask?.cancel()
    visible = true
  }

  func scheduleHide() {
    hideTask?.cancel()
    hideTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(3))
      guard !Task.isCancelled else { return }
      self?.visible = false
    }
  }
}
