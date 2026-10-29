import SwiftUI

struct DemoHistoryFilterBar: View {
  @Environment(\.themePalette) private var palette
  enum Filter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case week = "This week"
    case month = "This month"
    case older = "Older"
  }

  @Binding var selection: Filter
  @Binding var selectedDate: Date?
  let resultCount: Int
  @State private var showsCalendar = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("\(resultCount) \(resultCount == 1 ? "video" : "videos")")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          ForEach(Filter.allCases, id: \.self) { filter in
            Button {
              withAnimation(.easeInOut(duration: 0.18)) {
                selection = filter
              }
              if filter == .older {
                showsCalendar = true
              }
            } label: {
              Text(label(for: filter))
                .font(.caption.weight(.semibold))
                .foregroundStyle(selection == filter ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                  selection == filter
                    ? Color.accentColor
                    : palette.surface
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .sheet(isPresented: $showsCalendar) {
      NavigationStack {
        DatePicker(
          "History date",
          selection: selectedDateBinding,
          in: ...Date(),
          displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .padding()
        .navigationTitle("Choose a date")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              selection = .older
              showsCalendar = false
            }
          }
        }
      }
      .presentationDetents([.medium])
    }
  }

  private var selectedDateBinding: Binding<Date> {
    Binding(
      get: {
        selectedDate
          ?? Calendar.current.date(byAdding: .day, value: -2, to: Date())
          ?? Date()
      },
      set: { selectedDate = $0 }
    )
  }

  private func label(for filter: Filter) -> String {
    guard filter == .older, let selectedDate else { return filter.rawValue }
    return selectedDate.formatted(.dateTime.month(.abbreviated).day())
  }
}
