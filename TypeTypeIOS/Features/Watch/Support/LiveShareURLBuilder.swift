import Foundation
import SwiftUI

enum LiveShareURLBuilder {
  static func video(
    serverURL: URL?,
    sourceURL: String
  ) -> URL? {
    guard let source = URL(string: sourceURL) else { return nil }
    guard let serverURL,
      var components = URLComponents(
        url: serverURL,
        resolvingAgainstBaseURL: false
      )
    else {
      return source
    }

    var basePath = components.path
    if basePath.hasSuffix("/") {
      basePath.removeLast()
    }
    if basePath.hasSuffix("/api") {
      basePath.removeLast(4)
    }
    components.path = "\(basePath)/watch"
    components.queryItems = [
      URLQueryItem(name: "v", value: sourceURL),
    ]
    components.fragment = nil
    return components.url ?? source
  }

  /// The untouched source link (e.g. the YouTube URL) shared when the
  /// user picks "Original link" instead of the TypeType instance link.
  static func original(sourceURL: String) -> URL? {
    URL(string: sourceURL)
  }
}

/// System share sheet for a single shared URL.
struct LiveShareActivityView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(
    context: Context
  ) -> UIActivityViewController {
    UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: Context
  ) {}
}

/// Share button with a "share as" step: a small confirmation dialog
/// asks for the TypeType instance link (default) or the original source
/// link before the system share sheet opens for the chosen URL.
struct LiveShareAsLinkButton<Label: View>: View {
  let typeTypeURL: URL?
  let originalURL: URL?
  private let label: Label

  @State private var presentsLinkChoice = false
  @State private var shareSheetURL: URL?

  init(
    typeTypeURL: URL?,
    originalURL: URL?,
    @ViewBuilder label: () -> Label
  ) {
    self.typeTypeURL = typeTypeURL
    self.originalURL = originalURL
    self.label = label()
  }

  var body: some View {
    Button {
      presentsLinkChoice = true
    } label: {
      label
    }
    .confirmationDialog(
      "Share as",
      isPresented: $presentsLinkChoice,
      titleVisibility: .visible
    ) {
      if let typeTypeURL {
        Button("TypeType link") {
          shareSheetURL = typeTypeURL
        }
      }
      if let originalURL {
        Button("Original link") {
          shareSheetURL = originalURL
        }
      }
      Button("Cancel", role: .cancel) {}
    }
    .sheet(isPresented: shareSheetBinding) {
      if let shareSheetURL {
        LiveShareActivityView(url: shareSheetURL)
      }
    }
  }

  private var shareSheetBinding: Binding<Bool> {
    Binding(
      get: { shareSheetURL != nil },
      set: { if !$0 { shareSheetURL = nil } }
    )
  }
}
