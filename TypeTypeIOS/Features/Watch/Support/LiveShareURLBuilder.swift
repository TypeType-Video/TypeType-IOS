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

  static func original(sourceURL: String) -> URL? {
    URL(string: sourceURL)
  }
}

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
    .popover(
      isPresented: $presentsLinkChoice,
      attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
      arrowEdge: .top
    ) {
      LiveShareChoiceCard(
        hasOriginal: originalURL != nil,
        onTypeType: { shareSheetURL = typeTypeURL },
        onOriginal: { shareSheetURL = originalURL },
        onCancel: { presentsLinkChoice = false }
      )
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

struct LiveShareChoiceCard: View {
  var hasOriginal = true
  let onTypeType: () -> Void
  let onOriginal: () -> Void
  let onCancel: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      row("TypeType link", action: onTypeType)
      Divider()
      if hasOriginal {
        row("Original link", action: onOriginal)
        Divider()
      }
      row("Cancel", action: onCancel)
    }
    .frame(width: 280)
    .presentationCompactAdaptation(.popover)
    .accessibilityIdentifier("live.share.choice")
  }

  private func row(_ title: String, action: @escaping () -> Void) -> some View {
    Button {
      action()
    } label: {
      Text(title)
        .foregroundStyle(title == "Cancel" ? Color.systemRed : .primary)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
