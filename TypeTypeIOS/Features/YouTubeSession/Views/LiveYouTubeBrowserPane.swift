import SwiftUI

struct LiveYouTubeBrowserPane: View {
  @ObservedObject var browser: LiveYouTubeRemoteBrowser
  let onCancel: () -> Void
  let onFinished: () -> Void
  @State private var typed = ""
  @State private var lastDrag: CGSize = .zero
  @FocusState private var typing: Bool

  var body: some View {
    VStack(spacing: 12) {
      Text(phaseText)
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
      GeometryReader { proxy in
        ZStack {
          Color.black
          if let frame = browser.frame {
            Image(uiImage: frame)
              .resizable()
              .scaledToFit()
          } else {
            ProgressView().tint(.white)
          }
        }
        .contentShape(Rectangle())
        .gesture(tap(in: proxy.size))
        .simultaneousGesture(scroll)
        .onAppear { resize(proxy.size) }
        .onChange(of: proxy.size) { _, size in resize(size) }
        .accessibilityLabel(Text("YouTube sign-in window"))
        .accessibilityHint(Text("Tap a field, then type with the keyboard below."))
      }
      .aspectRatio(9 / 16, contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      TextField("Type here to fill the selected field", text: $typed)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .focused($typing)
        .submitLabel(.go)
        .onSubmit { browser.send(.key("Enter")) }
        .onChange(of: typed) { old, new in
          LiveYouTubeBrowserInput.edit(from: old, to: new).forEach(browser.send)
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      Button("Cancel sign-in", role: .cancel, action: onCancel)
    }
    .onChange(of: browser.phase) { _, phase in
      if phase == .connected || phase == .closed {
        onFinished()
      }
    }
  }

  private var phaseText: String {
    switch browser.phase {
    case .idle, .connecting, .opening: String(localized: "Opening the sign-in window…")
    case .awaitingLogin: String(localized: "Sign in to YouTube in the window below.")
    case .capturingSession: String(localized: "Saving the session…")
    case .connected: String(localized: "YouTube session connected")
    case .closed: String(localized: "Sign-in window closed")
    case .error: browser.errorMessage ?? String(localized: "The sign-in browser closed unexpectedly.")
    }
  }

  private func tap(in container: CGSize) -> some Gesture {
    SpatialTapGesture().onEnded { value in
      guard let frame = browser.frame,
        let point = LiveYouTubeBrowserInput.point(value.location, in: container, frame: frame.size)
      else { return }
      browser.send(.tap(x: point.x, y: point.y))
      typed = ""
      typing = true
    }
  }

  private var scroll: some Gesture {
    DragGesture(minimumDistance: 8)
      .onChanged { value in
        let delta = CGSize(
          width: value.translation.width - lastDrag.width,
          height: value.translation.height - lastDrag.height
        )
        lastDrag = value.translation
        browser.send(.wheel(deltaX: -delta.width, deltaY: -delta.height))
      }
      .onEnded { _ in lastDrag = .zero }
  }

  private func resize(_ size: CGSize) {
    browser.send(.resize(width: Int(size.width), height: Int(size.height)))
  }
}
