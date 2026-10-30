import SwiftUI

struct LiveOptionMenu<Option: Hashable>: View {
  let title: String
  @Binding var selection: Option
  let options: [(value: Option, label: String)]
  @State private var isPresented = false
  @Environment(\.themePalette) private var palette

  init(
    _ title: String,
    selection: Binding<Option>,
    options: [(Option, String)]
  ) {
    self.title = title
    self._selection = selection
    self.options = options.map { (value: $0.0, label: $0.1) }
  }

  var body: some View {
    Button {
      isPresented = true
    } label: {
      HStack(spacing: 12) {
        Text(localized(title))
          .foregroundStyle(palette.textPrimary)
        Spacer(minLength: 12)
        Text(localized(currentLabel))
          .foregroundStyle(palette.textSecondary)
          .lineLimit(1)
          .popover(
            isPresented: $isPresented,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .top
          ) {
            VStack(alignment: .leading, spacing: 0) {
              ForEach(options.indices, id: \.self) { index in
                Button {
                  selection = options[index].value
                  isPresented = false
                } label: {
                  HStack(spacing: 12) {
                    Text(localized(options[index].label))
                      .foregroundStyle(palette.textPrimary)
                    Spacer(minLength: 12)
                    if options[index].value == selection {
                      Image(systemName: "checkmark")
                        .foregroundStyle(palette.accent)
                    }
                  }
                  .padding(.horizontal, 16)
                  .frame(minHeight: 44)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < options.count - 1 {
                  Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                }
              }
            }
            .frame(width: 280)
            .presentationCompactAdaptation(.popover)
            .presentationBackground(palette.surface)
            .presentationCornerRadius(20)
          }
      }
      .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
    }
    .buttonStyle(.plain)
    .liveRowFill()
  }

  private func localized(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: nil, table: nil)
  }

  private var currentLabel: String {
    options.first(where: { $0.value == selection })?.label ?? ""
  }
}
