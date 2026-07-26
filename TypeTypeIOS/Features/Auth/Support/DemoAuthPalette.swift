import SwiftUI

struct DemoAuthPalette {
  let isLight: Bool

  var primaryText: Color {
    isLight ? Color(red: 0.08, green: 0.09, blue: 0.11) : .white
  }

  var secondaryText: Color {
    isLight ? Color.black.opacity(0.58) : Color.white.opacity(0.62)
  }

  var placeholderText: Color {
    isLight ? Color.black.opacity(0.42) : Color.white.opacity(0.42)
  }

  var cardSurface: Color {
    isLight
      ? Color.white.opacity(0.9)
      : Color(red: 0.055, green: 0.06, blue: 0.07).opacity(0.94)
  }

  var fieldSurface: Color {
    isLight ? Color.black.opacity(0.055) : Color.black.opacity(0.36)
  }

  var border: Color {
    isLight ? Color.black.opacity(0.12) : Color.white.opacity(0.14)
  }

  var buttonSurface: Color {
    isLight ? Color.black : Color.white
  }

  var buttonText: Color {
    isLight ? Color.white : Color.black
  }
}
