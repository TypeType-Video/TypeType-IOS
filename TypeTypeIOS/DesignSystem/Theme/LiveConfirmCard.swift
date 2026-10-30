import SwiftUI

struct LiveConfirmCard: View {
  let title: String
  var message: String? = nil
  let confirmTitle: String
  var destructive = true
  let onConfirm: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        Text(LocalizedStringKey(title))
          .font(.headline)
          .multilineTextAlignment(.center)
        if let message, !message.isEmpty {
          Text(LocalizedStringKey(message))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      Button(role: destructive ? ButtonRole.destructive : nil) {
        dismiss()
        onConfirm()
      } label: {
        Text(LocalizedStringKey(confirmTitle))
          .fontWeight(.semibold)
          .foregroundStyle(
            destructive ? AnyShapeStyle(Color.systemRed) : AnyShapeStyle(.tint)
          )
          .frame(maxWidth: .infinity, minHeight: 50)
      }
      .buttonStyle(.plain)

      Divider()

      Button("Cancel") { dismiss() }
        .fontWeight(.semibold)
        .foregroundStyle(.tint)
        .frame(maxWidth: .infinity, minHeight: 50)
        .buttonStyle(.plain)
    }
    .frame(width: 280)
    .presentationCompactAdaptation(.popover)
  }
}

extension View {
  func liveConfirmPopover(
    isPresented: Binding<Bool>,
    title: String,
    message: String? = nil,
    confirmTitle: String,
    destructive: Bool = true,
    onConfirm: @escaping () -> Void
  ) -> some View {
    popover(
      isPresented: isPresented,
      attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
      arrowEdge: .top
    ) {
      LiveConfirmCard(
        title: title,
        message: message,
        confirmTitle: confirmTitle,
        destructive: destructive,
        onConfirm: onConfirm
      )
    }
  }
}
