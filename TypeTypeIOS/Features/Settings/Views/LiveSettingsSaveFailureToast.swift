import SwiftUI

struct LiveSettingsSaveFailureToast: ViewModifier {
  @ObservedObject var viewModel: LiveSettingsViewModel
  @Environment(\.liveToasts) private var toasts

  func body(content: Content) -> some View {
    content.onChange(of: viewModel.errorMessage) { _, message in
      guard let message else { return }
      toasts?.show(String(localized: "Change not saved"), detail: message, tone: .failure)
      viewModel.dismissError()
    }
  }
}

extension View {
  func liveSettingsSaveFailureToast(_ viewModel: LiveSettingsViewModel) -> some View {
    modifier(LiveSettingsSaveFailureToast(viewModel: viewModel))
  }
}
