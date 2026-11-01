import Foundation

@MainActor
final class LiveNativeControlsState: ObservableObject {
  @Published var visible = true
  var staysVisible = false {
    didSet {
      if staysVisible { keepVisible() }
    }
  }
  // The AirPlay menu closes with the button that opened it, so the controls wait for it.
  private var isHeld = false
  private var hideTask: Task<Void, Never>?
  private var tapTask: Task<Void, Never>?

  func tap() {
    tapTask?.cancel()
    tapTask = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(260))
      guard !Task.isCancelled, let self else { return }
      guard !staysVisible, !isHeld else { return }
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

  func hold(_ held: Bool) {
    isHeld = held
    if held { keepVisible() } else { scheduleHide() }
  }

  func scheduleHide() {
    hideTask?.cancel()
    guard !staysVisible, !isHeld else { return }
    hideTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(3))
      guard !Task.isCancelled else { return }
      self?.visible = false
    }
  }
}
