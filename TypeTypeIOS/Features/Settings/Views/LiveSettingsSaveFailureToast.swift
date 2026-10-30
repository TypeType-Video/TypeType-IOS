import SwiftUI

struct LiveSettingsSaveFailureToast: ViewModifier {
  @ObservedObject var viewModel: LiveSettingsViewModel
  @Environment(\.themePalette) private var palette
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .bottom) {
        if let message = viewModel.errorMessage {
          toast(message)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .transition(.liveBanner(reduceMotion: reduceMotion))
        }
      }
      .animation(.smooth(duration: 0.3), value: viewModel.errorMessage)
  }

  @ViewBuilder
  private func toast(_ message: String) -> some View {
    let card = HStack(spacing: 12) {
      Image(systemName: "exclamationmark.icloud.fill")
        .font(.title3.weight(.semibold))
        .foregroundStyle(palette.accent)
      VStack(alignment: .leading, spacing: 2) {
        Text("Change not saved")
          .font(.callout.weight(.semibold))
        Text(message)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("live.settings.save-failure")
    .task(id: message) {
      try? await Task.sleep(for: .seconds(3.5))
      viewModel.dismissError()
    }
    .onTapGesture { viewModel.dismissError() }

    if #available(iOS 26.0, *) {
      card.glassEffect(.regular, in: .capsule)
    } else {
      card.background(.regularMaterial, in: Capsule())
    }
  }
}

extension View {
  func liveSettingsSaveFailureToast(_ viewModel: LiveSettingsViewModel) -> some View {
    modifier(LiveSettingsSaveFailureToast(viewModel: viewModel))
  }
}
