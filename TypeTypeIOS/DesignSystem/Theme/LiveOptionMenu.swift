import SwiftUI

struct LiveOptionMenu<Option: Hashable>: View {
  let title: String
  @Binding var selection: Option
  let options: [(value: Option, label: String)]
  var help: LocalizedStringKey?
  var disabledReason: LocalizedStringKey?

  init(
    _ title: String,
    selection: Binding<Option>,
    options: [(Option, String)],
    help: LocalizedStringKey? = nil,
    disabledReason: LocalizedStringKey? = nil
  ) {
    self.title = title
    self._selection = selection
    self.options = options.map { (value: $0.0, label: $0.1) }
    self.help = help
    self.disabledReason = disabledReason
  }

  var body: some View {
    Picker(selection: $selection) {
      ForEach(options.indices, id: \.self) { index in
        Text(localized(options[index].label)).tag(options[index].value)
      }
    } label: {
      Text(LocalizedStringKey(title))
      if let subtitle = disabledReason ?? help {
        Text(subtitle)
      }
    }
    .pickerStyle(.menu)
    .disabled(disabledReason != nil)
    .liveRowFill()
  }

  private func localized(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: nil, table: nil)
  }
}
