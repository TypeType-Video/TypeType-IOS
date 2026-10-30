import SwiftUI

struct LiveOptionMenu<Option: Hashable>: View {
  let title: String
  @Binding var selection: Option
  let options: [(value: Option, label: String)]
  var help: LocalizedStringKey?
  var disabledReason: LocalizedStringKey?
  var opensList = false

  init(
    _ title: String,
    selection: Binding<Option>,
    options: [(Option, String)],
    help: LocalizedStringKey? = nil,
    disabledReason: LocalizedStringKey? = nil,
    opensList: Bool = false
  ) {
    self.title = title
    self._selection = selection
    self.options = options.map { (value: $0.0, label: $0.1) }
    self.help = help
    self.disabledReason = disabledReason
    self.opensList = opensList
  }

  var body: some View {
    row
      .disabled(disabledReason != nil)
      .liveRowFill()
  }

  @ViewBuilder
  private var row: some View {
    if opensList {
      NavigationLink {
        LiveOptionListPage(title: title, selection: $selection, options: options)
      } label: {
        HStack(spacing: 12) {
          LiveSettingText(title: LocalizedStringKey(title), detail: disabledReason ?? help)
          Spacer(minLength: 8)
          Text(currentLabel)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    } else {
      HStack(spacing: 12) {
        LiveSettingText(title: LocalizedStringKey(title), detail: disabledReason ?? help)
        Spacer(minLength: 8)
        Menu {
          Picker(selection: $selection) {
            ForEach(options.indices, id: \.self) { index in
              Text(LiveOptionMenu.localized(options[index].label)).tag(options[index].value)
            }
          } label: {
            EmptyView()
          }
          .pickerStyle(.inline)
        } label: {
          HStack(spacing: 4) {
            Text(currentLabel)
            Image(systemName: "chevron.up.chevron.down")
              .font(.footnote.weight(.semibold))
          }
          .lineLimit(1)
          .fixedSize()
        }
        .accessibilityLabel(Text(LocalizedStringKey(title)))
        .accessibilityValue(Text(currentLabel))
      }
    }
  }

  private var currentLabel: String {
    Self.localized(options.first { $0.value == selection }?.label ?? "")
  }

  static func localized(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: nil, table: nil)
  }
}

struct LiveSettingText: View {
  let title: LocalizedStringKey
  var detail: LocalizedStringKey?

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
      if let detail {
        Text(detail)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

struct LiveOptionListPage<Option: Hashable>: View {
  let title: String
  @Binding var selection: Option
  let options: [(value: Option, label: String)]
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    List {
      LiveSection {
        ForEach(options.indices, id: \.self) { index in
          Button {
            selection = options[index].value
            dismiss()
          } label: {
            HStack {
              Text(LiveOptionMenu<Option>.localized(options[index].label))
                .foregroundStyle(.primary)
              Spacer()
              if options[index].value == selection {
                Image(systemName: "checkmark")
                  .foregroundStyle(.tint)
              }
            }
          }
          .accessibilityAddTraits(options[index].value == selection ? .isSelected : [])
        }
      }
    }
    .liveGroupedList()
    .navigationTitle(LocalizedStringKey(title))
    .navigationBarTitleDisplayMode(.inline)
  }
}
