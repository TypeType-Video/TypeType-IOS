import SwiftUI

struct LiveHistoryDateSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var date: Date
  let onSelect: (Date) -> Void

  init(
    initialDate: Date = Date(),
    onSelect: @escaping (Date) -> Void
  ) {
    _date = State(initialValue: initialDate)
    self.onSelect = onSelect
  }

  var body: some View {
    NavigationStack {
      DatePicker(
        "History date",
        selection: $date,
        in: ...Date(),
        displayedComponents: .date
      )
      .datePickerStyle(.graphical)
      .padding()
      .navigationTitle("Choose a date")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Apply") {
            onSelect(date)
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium])
  }
}
