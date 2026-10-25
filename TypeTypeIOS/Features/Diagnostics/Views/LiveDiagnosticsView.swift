import SwiftUI
import UIKit

struct LiveDiagnosticsView: View {
  let store: LiveDiagnosticsStore
  let scopeProvider: () -> LiveDiagnosticScope?
  @State private var entries: [LiveDiagnosticEntry] = []
  @State private var isLoading = true
  @State private var confirmsClear = false
  @State private var copiedRequestID: String?

  var body: some View {
    List {
      Section {
        Text(
          "Recent requests are stored only on this device. Routes are sanitized and never include query values, media URLs, tokens, or passwords."
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }

      if isLoading {
        Section {
          HStack {
            Spacer()
            ProgressView("Loading diagnostics")
            Spacer()
          }
        }
      } else if entries.isEmpty {
        Section {
          ContentUnavailableView(
            "No diagnostics yet",
            systemImage: "checkmark.shield",
            description: Text(
              "Requests made to this TypeType instance will appear here."
            )
          )
        }
      } else {
        Section {
          ForEach(entries) { entry in
            LiveDiagnosticRow(
              entry: entry,
              copiedRequestID: $copiedRequestID
            )
          }
        } header: { Text("Recent requests").liveSectionHeader() }
      }
    }
      .listStyle(.insetGrouped)
    .navigationTitle("Diagnostics")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        if !entries.isEmpty {
          ShareLink(item: report) {
            Image(systemName: "square.and.arrow.up")
          }
          .accessibilityLabel("Share diagnostics")
          Button(role: .destructive) {
            confirmsClear = true
          } label: {
            Image(systemName: "trash")
          }
          .accessibilityLabel("Clear diagnostics")
        }
      }
    }
    .refreshable { await reload() }
    .task { await reload() }
    .confirmationDialog(
      "Clear diagnostics on this device?",
      isPresented: $confirmsClear,
      titleVisibility: .visible
    ) {
      Button("Clear diagnostics", role: .destructive) {
        Task { await clear() }
      }
      Button("Cancel", role: .cancel) {}
    }
    .overlay(alignment: .bottom) {
      if copiedRequestID != nil {
        Text("Request ID copied")
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, 14)
          .padding(.vertical, 9)
          .background(.regularMaterial, in: Capsule())
          .padding(.bottom, 16)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .accessibilityIdentifier("live.diagnostics.screen")
  }

  private func reload() async {
    guard let scope = scopeProvider() else {
      entries = []
      isLoading = false
      return
    }
    entries = await store.entries(for: scope)
    isLoading = false
  }

  private func clear() async {
    guard let scope = scopeProvider() else { return }
    await store.clear(scope: scope)
    await reload()
  }

  private var report: String {
    var lines = [
      "TypeType iOS diagnostics",
      "Generated: \(Date().formatted(.iso8601))",
      "",
    ]
    lines.append(
      contentsOf: entries.map { entry in
        let status = entry.statusCode.map(String.init) ?? "network-error"
        let requestID = entry.requestID.map { " request-id=\($0)" } ?? ""
        return "\(entry.timestamp.formatted(.iso8601)) \(entry.method) \(entry.route) status=\(status) duration=\(entry.durationMilliseconds)ms\(requestID)"
      }
    )
    return lines.joined(separator: "\n")
  }
}
