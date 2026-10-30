import SwiftUI

struct LiveSettingToggle: View {
  let title: LocalizedStringKey
  var help: LocalizedStringKey?
  @Binding var isOn: Bool
  var disabledReason: LocalizedStringKey?

  init(
    _ title: LocalizedStringKey,
    help: LocalizedStringKey? = nil,
    isOn: Binding<Bool>,
    disabledReason: LocalizedStringKey? = nil
  ) {
    self.title = title
    self.help = help
    self._isOn = isOn
    self.disabledReason = disabledReason
  }

  var body: some View {
    Toggle(isOn: $isOn) {
      Text(title)
      if let subtitle = disabledReason ?? help {
        Text(subtitle)
      }
    }
    .disabled(disabledReason != nil)
    .liveRowFill()
  }
}
