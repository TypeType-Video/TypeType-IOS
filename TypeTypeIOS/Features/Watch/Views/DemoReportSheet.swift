import SwiftUI

struct DemoReportSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var session: DemoSessionStore
  let onSent: () -> Void

  @State private var category = "Playback"
  @State private var details = ""
  @State private var includesDiagnostics = true

  var body: some View {
    NavigationStack {
      Form {
        Section("What happened?") {
          Picker("Category", selection: $category) {
            Text("Playback").tag("Playback")
            Text("Audio language").tag("Audio language")
            Text("Subtitles").tag("Subtitles")
            Text("Interface").tag("Interface")
            Text("Functionality").tag("Functionality")
          }
          TextField(
            "Describe the issue",
            text: $details,
            axis: .vertical
          )
          .lineLimit(4...8)
        }

        Section("Diagnostics") {
          Toggle("Attach technical details", isOn: $includesDiagnostics)
          if includesDiagnostics {
            LabeledContent("Playback", value: "SABR")
            LabeledContent("App", value: "TypeType iOS mock")
            LabeledContent("Personal data", value: "Not included")
          }
        }
      }
      .navigationTitle("Report a problem")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Send") {
            session.submitMockIssue(
              title: "\(category) report from Watch",
              category: category,
              detail: details,
              diagnostics: includesDiagnostics
                ? "SABR · TypeType iOS mock · no personal data"
                : "Not attached"
            )
            onSent()
            dismiss()
          }
          .disabled(details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    .presentationDetents([.medium, .large])
    .preferredColorScheme(session.preferences.colorScheme)
    .accessibilityIdentifier("demo.watch.report")
  }
}
