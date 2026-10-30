import UIKit

extension LiveAppPreferences {
  func usesAccessiblePlayerControls(voiceOver: Bool = UIAccessibility.isVoiceOverRunning) -> Bool {
    playerAccessibleControlsEnabled || voiceOver
  }
}
