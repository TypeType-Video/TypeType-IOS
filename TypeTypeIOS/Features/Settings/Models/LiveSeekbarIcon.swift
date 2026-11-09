import Foundation

enum LiveSeekbarIcon: Equatable {
  case typeType
  case custom(URL)
  case plain

  init(settings: LiveSettings) {
    switch LiveSeekbarIconChoice(rawValue: settings.seekbarIcon ?? "") ?? .typeType {
    case .typeType: self = .typeType
    case .plain: self = .plain
    case .custom:
      if let url = LiveImageURLResolver.resolve(settings.seekbarIconUrl) {
        self = .custom(url)
      } else {
        self = .typeType
      }
    }
  }
}

enum LiveSeekbarIconChoice: String, CaseIterable, Identifiable {
  case typeType = "typetype"
  case custom
  case plain = "none"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .typeType: String(localized: "TypeType")
    case .custom: String(localized: "My image")
    case .plain: String(localized: "None")
    }
  }

  static func shown(for settings: LiveSettings) -> Self {
    switch LiveSeekbarIcon(settings: settings) {
    case .typeType: .typeType
    case .custom: .custom
    case .plain: .plain
    }
  }
}
