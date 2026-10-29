import SwiftUI

extension LiveCommentsSectionView {
  func statusCard<Actions: View>(
    title: String,
    message: String,
    systemImage: String,
    @ViewBuilder actions: () -> Actions
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
      Text(message)
        .font(.footnote)
        .foregroundStyle(.secondary)
      actions()
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      palette.surface,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
  }

  func statusCard<Actions: View>(
    title: LocalizedStringKey,
    message: LocalizedStringKey,
    systemImage: String,
    @ViewBuilder actions: () -> Actions
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
      Text(message)
        .font(.footnote)
        .foregroundStyle(.secondary)
      actions()
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      palette.surface,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
  }

  func statusCard(
    title: LocalizedStringKey,
    message: LocalizedStringKey,
    systemImage: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
      Text(message)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      palette.surface,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
  }

  func statusCard(
    title: String,
    message: String,
    systemImage: String
  ) -> some View {
    statusCard(
      title: title,
      message: message,
      systemImage: systemImage
    ) {
      EmptyView()
    }
  }
}
