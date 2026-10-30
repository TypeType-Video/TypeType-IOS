import SwiftUI
import UIKit

// Navigation bars, tab bars and list cells are UIKit views: they read the palette from a window trait, not the
// SwiftUI environment.
struct ThemeChrome: Equatable {
  var background: UIColor
  var row: UIColor
}

private struct ThemeChromeTrait: UITraitDefinition {
  static let defaultValue = ThemeChrome(
    background: .secondarySystemBackground,
    row: .secondarySystemBackground
  )
}

extension ThemeChrome {
  @MainActor
  static func installAppearance() {
    let background = UIColor { $0[ThemeChromeTrait.self].background }
    let row = UIColor { $0[ThemeChromeTrait.self].row }
    UITableViewHeaderFooterView.appearance().backgroundColor = .clear
    UITableViewCell.appearance().backgroundColor = row
    UICollectionViewCell.appearance().backgroundColor = row
    UITableView.appearance().backgroundColor = background
    UICollectionView.appearance().backgroundColor = background
    let navigation = UINavigationBarAppearance()
    navigation.configureWithOpaqueBackground()
    navigation.backgroundColor = background
    UINavigationBar.appearance().standardAppearance = navigation
    UINavigationBar.appearance().scrollEdgeAppearance = navigation
    UINavigationBar.appearance().compactAppearance = navigation
    let tab = UITabBarAppearance()
    tab.configureWithOpaqueBackground()
    tab.backgroundColor = background
    UITabBar.appearance().standardAppearance = tab
    UITabBar.appearance().scrollEdgeAppearance = tab
  }
}

struct ThemeChromeBridge: UIViewRepresentable {
  let chrome: ThemeChrome

  func makeUIView(context: Context) -> BridgeView {
    BridgeView()
  }

  func updateUIView(_ view: BridgeView, context: Context) {
    view.chrome = chrome
  }

  final class BridgeView: UIView {
    var chrome: ThemeChrome? {
      didSet { apply() }
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      apply()
    }

    private func apply() {
      guard let chrome, let window else { return }
      window.traitOverrides[ThemeChromeTrait.self] = chrome
    }
  }
}
