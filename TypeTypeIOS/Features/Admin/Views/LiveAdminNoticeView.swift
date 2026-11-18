import SwiftUI

struct LiveAdminNoticeView: View {
  let service: LiveAdminExtrasServiceProtocol
  @State private var kind = "update"
  @State private var message = ""
  @State private var busy = false
  @State private var result: String?

  var body: some View {
    List {
      LiveSection {
        Picker("Kind", selection: $kind) {
          Text("Update coming").tag("update")
          Text("Maintenance").tag("maintenance")
          Text("Restarting").tag("restart")
        }
        TextField("Message (optional)", text: $message, axis: .vertical)
          .lineLimit(1...3)
        Button("Send to everyone") { Task { await run { try await service.announce(request) } } }
          .disabled(busy)
        Button("Clear the notice", role: .destructive) { Task { await run { try await service.clearNotice() } } }
          .disabled(busy)
      } footer: {
        Text(verbatim: result ?? String(localized: "Every open app shows the notice at once, and again when it connects."))
          .liveSettingsFooter()
      }
    }
    .liveGroupedList()
    .navigationTitle("Server notice")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var request: LiveAdminNoticeRequest {
    let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
    return LiveAdminNoticeRequest(kind: kind, message: text.isEmpty ? nil : String(text.prefix(280)), resumeInSeconds: nil)
  }

  private func run(_ action: () async throws -> Void) async {
    busy = true
    defer { busy = false }
    do {
      try await action()
      result = String(localized: "Done.")
    } catch {
      result = LiveUserError(error).message ?? String(localized: "The change could not be saved.")
    }
  }
}

struct LiveAdminRecommenderView: View {
  let service: LiveAdminExtrasServiceProtocol
  @State private var status: LiveAdminRecommenderStatus?
  @State private var feedback: LiveAdminRecommenderFeedback?
  @State private var failed = false

  var body: some View {
    List {
      if let status {
        LiveSection {
          row("Reachable", status.reachable ? String(localized: "Yes") : String(localized: "No"))
          if let health = status.healthMs { row("Health check", "\(health) ms") }
          row("Algorithms", status.algorithms.map(\.name).joined(separator: ", "))
          row("Pages built", "\(status.pagesBuilt)")
          row("From cache", "\(status.pagesFromCache)")
          row("Fallbacks", "\(status.fallbacks)")
          row("Average build", "\(Int(status.averageBuildMs)) ms")
          row("Stream requests refused", "\(status.streamRequestsRefused) / \(status.streamRequests)")
        } header: { Text("Status").liveSectionHeader() }
      }
      if let feedback {
        LiveSection {
          row("Users with an algorithm", "\(feedback.usersEnabled)")
          ForEach(feedback.verdicts, id: \.algorithmId) { verdict in
            row(LocalizedStringKey(name(verdict.algorithmId)), "+\(verdict.good) · −\(verdict.bad) · \(verdict.notForMe)")
          }
          ForEach(Array(feedback.comments.prefix(30).enumerated()), id: \.offset) { _, comment in
            if let text = comment.comment {
              VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: text)
                Text(verbatim: "\(name(comment.algorithmId)) · \(comment.verdict)").font(.footnote).foregroundStyle(.secondary)
              }
            }
          }
        } header: { Text("Opinions").liveSectionHeader() }
      }
      if failed { Text("The algorithm could not be loaded.").foregroundStyle(.secondary) }
    }
    .liveGroupedList()
    .navigationTitle("Algorithm")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      async let loadedStatus = try? service.recommenderStatus()
      async let loadedFeedback = try? service.recommenderFeedback()
      (status, feedback) = await (loadedStatus, loadedFeedback)
      failed = status == nil && feedback == nil
    }
  }

  private func name(_ id: String) -> String { status?.algorithms.first { $0.id == id }?.name ?? id }

  private func row(_ title: LocalizedStringKey, _ value: String) -> some View {
    LabeledContent(title) { Text(verbatim: value).foregroundStyle(.secondary) }
  }
}
