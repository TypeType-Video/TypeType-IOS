import SwiftUI
import UniformTypeIdentifiers

struct ZipPickerButton: View {
  let title: String
  let disabled: Bool
  let allowsMultipleSelection: Bool
  let onSelect: ([URL]) -> Void

  @State private var isPresentingPicker: Bool = false

  var body: some View {
    Button(title) {
      isPresentingPicker = true
    }
    .disabled(disabled)
    .fileImporter(
      isPresented: $isPresentingPicker,
      allowedContentTypes: [.zip],
      allowsMultipleSelection: allowsMultipleSelection
    ) { result in
      guard case .success(let urls) = result else { return }
      onSelect(urls)
    }
  }
}
