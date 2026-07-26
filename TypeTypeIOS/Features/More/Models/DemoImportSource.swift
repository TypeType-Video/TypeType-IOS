import SwiftUI

enum DemoImportSource: String, CaseIterable, Identifiable {
  case youtube
  case pipePipe

  var id: String { rawValue }
  var shortName: String { self == .youtube ? "YouTube" : "PipePipe" }
  var title: String { "Import from \(shortName)" }

  var systemImage: String {
    self == .youtube ? "play.rectangle.fill" : "arrow.triangle.2.circlepath"
  }

  var summary: String {
    self == .youtube
      ? "Bring subscriptions and playlists from a Google Takeout archive."
      : "Restore history, subscriptions, playlists, and progress from a backup ZIP."
  }

  var tint: Color {
    self == .youtube ? .red : .purple
  }

  var gradient: LinearGradient {
    LinearGradient(
      colors: [tint.opacity(0.62), tint.opacity(0.16)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
