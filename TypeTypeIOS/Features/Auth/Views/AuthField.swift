import SwiftUI
import UIKit

struct AuthField: View {
  enum Kind {
    case name
    case email
    case password
  }

  let placeholder: LocalizedStringKey
  let kind: Kind
  let palette: AuthPalette
  @Binding var text: String
  @State private var revealsPassword = false

  var body: some View {
    HStack(spacing: 10) {
      field

      if kind == .password {
        Button {
          revealsPassword.toggle()
        } label: {
          Image(
            systemName: revealsPassword ? "eye.slash" : "eye"
          )
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(palette.secondaryText)
          .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
          revealsPassword ? "Hide password" : "Show password"
        )
      }
    }
    .padding(.horizontal, 13)
    .frame(minHeight: 48)
    .background(palette.fieldSurface)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(palette.border, lineWidth: 1)
    }
  }

  @ViewBuilder
  private var field: some View {
    if kind == .password && !revealsPassword {
      SecureField(
        "",
        text: $text,
        prompt: Text(placeholder).foregroundStyle(palette.placeholderText)
      )
        .textContentType(.password)
        .textInputAutocapitalization(.never)
        .foregroundStyle(palette.primaryText)
    } else {
      TextField(
        "",
        text: $text,
        prompt: Text(placeholder).foregroundStyle(palette.placeholderText)
      )
        .textContentType(textContentType)
        .textInputAutocapitalization(capitalization)
        .keyboardType(keyboardType)
        .foregroundStyle(palette.primaryText)
    }
  }

  private var textContentType: UITextContentType? {
    switch kind {
    case .name:
      return .name
    case .email:
      return .username
    case .password:
      return .password
    }
  }

  private var capitalization: TextInputAutocapitalization {
    kind == .name ? .words : .never
  }

  private var keyboardType: UIKeyboardType {
    kind == .email ? .emailAddress : .default
  }
}
