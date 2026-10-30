import SwiftUI
import UIKit

struct LiveToast: Equatable, Identifiable {
  enum Tone {
    case success
    case failure
    case info
  }

  let id = UUID()
  let title: String
  var detail: String?
  var tone = Tone.success

  var systemImage: String {
    switch tone {
    case .success: "checkmark.circle.fill"
    case .failure: "exclamationmark.triangle.fill"
    case .info: "info.circle.fill"
    }
  }
}

@MainActor
final class LiveToastCenter: ObservableObject {
  @Published private(set) var current: LiveToast?
  private var window: UIWindow?
  private var dismissTask: Task<Void, Never>?

  func show(_ toast: LiveToast) {
    installWindowIfNeeded()
    current = toast
    AccessibilityNotification.Announcement([toast.title, toast.detail].compactMap { $0 }.joined(separator: ". "))
      .post()
    dismissTask?.cancel()
    dismissTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(toast.tone == .failure ? 4 : 2.6))
      guard !Task.isCancelled else { return }
      self?.current = nil
    }
  }

  func show(_ title: String, detail: String? = nil, tone: LiveToast.Tone = .success) {
    show(LiveToast(title: title, detail: detail, tone: tone))
  }

  private func installWindowIfNeeded() {
    guard window == nil,
      let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive })
    else { return }
    let window = UIWindow(windowScene: scene)
    window.windowLevel = .alert + 1
    window.isUserInteractionEnabled = false
    let host = UIHostingController(rootView: LiveToastHost(center: self))
    host.view.backgroundColor = .clear
    window.rootViewController = host
    window.isHidden = false
    self.window = window
  }
}

private struct LiveToastHost: View {
  @ObservedObject var center: LiveToastCenter
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack {
      Spacer()
      if let toast = center.current {
        card(toast)
          .id(toast.id)
          .transition(.liveBanner(reduceMotion: reduceMotion))
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 96)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .animation(.smooth(duration: 0.3), value: center.current)
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private func card(_ toast: LiveToast) -> some View {
    let content = HStack(spacing: 12) {
      Image(systemName: toast.systemImage)
        .font(.title3.weight(.semibold))
        .foregroundStyle(toast.tone == .failure ? Color.orange : Color.green)
      VStack(alignment: .leading, spacing: 2) {
        Text(toast.title)
          .font(.callout.weight(.semibold))
        if let detail = toast.detail {
          Text(detail)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    if #available(iOS 26.0, *) {
      content.glassEffect(.regular, in: .capsule)
    } else {
      content.background(.regularMaterial, in: Capsule())
    }
  }
}

private struct LiveToastCenterKey: EnvironmentKey {
  static let defaultValue: LiveToastCenter? = nil
}

extension EnvironmentValues {
  var liveToasts: LiveToastCenter? {
    get { self[LiveToastCenterKey.self] }
    set { self[LiveToastCenterKey.self] = newValue }
  }
}
