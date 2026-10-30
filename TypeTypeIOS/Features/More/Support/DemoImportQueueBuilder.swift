import SwiftUI

struct DemoImportQueueBuilder: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var queue: [String]
  let onStart: () -> Void
  @State private var showsGuide = false

  var body: some View {
    NavigationStack {
      List {
        Section {
          Button("Open Google Takeout guide") {
            showsGuide.toggle()
          }
          if showsGuide {
            VStack(alignment: .leading, spacing: 7) {
              Text("1. Export YouTube and My Activity.")
              Text("2. Keep ZIP archives unchanged.")
              Text("3. Add every archive part below.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
          }
        }

        Section {
          ForEach(Array(queue.enumerated()), id: \.offset) { index, file in
            HStack {
              Image(systemName: "doc.zipper")
              Text(file)
              Spacer()
              Button("Remove", role: .destructive) {
                queue.remove(at: index)
              }
            }
          }
          Button("Add sample ZIP part", systemImage: "plus") {
            queue.append("takeout-part-\(queue.count + 1).zip")
          }
          Button("Clear queue", role: .destructive) {
            queue.removeAll()
          }
          .disabled(queue.isEmpty)
        } header: { Text("Archive queue").liveSectionHeader() }

        Section {
          Button {
            onStart()
            dismiss()
          } label: {
            Text("Start \(queue.count)-archive import")
              .frame(maxWidth: .infinity)
          }
          .disabled(queue.isEmpty)
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("YouTube archive queue")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }
}
