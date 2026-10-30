import SwiftUI

struct DemoBugReportView: View {
  @EnvironmentObject private var session: DemoSessionStore
  @State private var category = "Playback"
  @State private var details = ""
  @State private var includesDiagnostics = true
  @State private var didSubmit = false

  var body: some View {
    Form {
      Section {
        Picker("Category", selection: $category) {
          Text("Playback").tag("Playback")
          Text("Audio language").tag("Audio language")
          Text("Subtitles").tag("Subtitles")
          Text("Interface").tag("Interface")
          Text("Functionality").tag("Functionality")
          Text("Import").tag("Import")
          Text("Other").tag("Other")
        }
        TextField("What happened?", text: $details, axis: .vertical)
          .lineLimit(4...8)
      } header: { Text("Problem").liveSectionHeader() }

      Section {
        Toggle("Include privacy-safe diagnostics", isOn: $includesDiagnostics).liveRowFill()
        LabeledContent("App", value: "TypeType iOS mock")
        LabeledContent("Device", value: "iPhone simulator")
      } header: { Text("Diagnostics").liveSectionHeader() }

      Section {
        Button {
          session.submitMockIssue(
            title: "\(category) report from iOS",
            category: category,
            detail: details,
            diagnostics: includesDiagnostics
              ? "TypeType iOS mock · iPhone simulator"
              : "Not attached"
          )
          withAnimation(.snappy) {
            didSubmit = true
          }
        } label: {
          Label("Save report locally", systemImage: "ladybug.fill")
            .frame(maxWidth: .infinity)
        }
        .disabled(details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }

      if didSubmit {
        Section {
          Label(
            "Mock report saved and visible in Admin → Issues.",
            systemImage: "checkmark.circle.fill"
          )
            .foregroundStyle(.green)
        }
      }
    }
    .navigationTitle("Report a problem")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.bug-report.screen")
  }
}
