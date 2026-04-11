import SwiftUI

enum TypeTypeMotion {
  static let quickEase = Animation.easeInOut(duration: 0.18)
  static let panelSpring = Animation.spring(response: 0.32, dampingFraction: 0.86)
}
