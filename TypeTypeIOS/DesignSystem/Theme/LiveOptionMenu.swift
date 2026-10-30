import SwiftUI

enum LiveOptionIcon {
  case system(String)
  case asset(String)

  var image: Image {
    switch self {
    case let .system(name): Image(systemName: name)
    case let .asset(name): Image(name)
    }
  }
}

struct LiveOptionMenu<Option: Hashable>: View {
  let title: String
  @Binding var selection: Option
  let options: [(value: Option, label: String, icon: LiveOptionIcon?)]
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
    self.options = options.map { (value: $0.0, label: $0.1, icon: nil) }
    self.help = help
    self.disabledReason = disabledReason
    self.opensList = opensList
  }

  init(
    _ title: String,
    selection: Binding<Option>,
    options: [(Option, String, LiveOptionIcon)],
    help: LocalizedStringKey? = nil,
    disabledReason: LocalizedStringKey? = nil
  ) {
    self.title = title
    self._selection = selection
    self.options = options.map { (value: $0.0, label: $0.1, icon: $0.2) }
    self.help = help
    self.disabledReason = disabledReason
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
              LiveOptionMenu.label(options[index]).tag(options[index].value)
            }
          } label: {
            EmptyView()
          }
          .pickerStyle(.inline)
        } label: {
          HStack(spacing: 4) {
            if let icon = currentIcon {
              icon.image
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            }
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

  private var currentIcon: LiveOptionIcon? {
    options.first { $0.value == selection }?.icon
  }

  @ViewBuilder
  static func label(_ option: (value: Option, label: String, icon: LiveOptionIcon?)) -> some View {
    if let icon = option.icon {
      Label { Text(localized(option.label)) } icon: { icon.image }
    } else {
      Text(localized(option.label))
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
  let options: [(value: Option, label: String, icon: LiveOptionIcon?)]
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
              LiveOptionMenu<Option>.label(options[index])
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
