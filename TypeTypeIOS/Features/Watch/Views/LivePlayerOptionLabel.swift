import SwiftUI

struct LivePlayerOptionLabel: View {
  let title: LocalizedStringKey
  let icon: String
  var detail: LocalizedStringKey?

  init(_ title: LocalizedStringKey, icon: String, detail: LocalizedStringKey? = nil) {
    self.title = title
    self.icon = icon
    self.detail = detail
  }

  var body: some View {
    Label {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        if let detail {
          Text(detail)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    } icon: {
      LiveSettingsIconTile(icon: icon)
    }
  }
}
