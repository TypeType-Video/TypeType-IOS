import SwiftUI

struct DemoImportFlowView: View {
  @Environment(\.themePalette) private var palette
  enum Phase {
    case ready
    case importing
    case complete
    case failed
  }

  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var session: DemoSessionStore
  let source: DemoImportSource
  @State private var phase = Phase.ready
  @State private var progress = 0.0
  @State private var queue: [String] = []
  @State private var showsQueueBuilder = false
  @State private var importedArchiveCount = 1

  var body: some View {
    NavigationStack {
      VStack(spacing: 22) {
        Image(systemName: statusSymbol)
          .font(.system(size: 58))
          .foregroundStyle(phase == .complete ? .green : source.tint)
        Text(title)
          .font(.title2.weight(.bold))
          .foregroundStyle(.primary)
        Text(message)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        if phase == .importing {
          ProgressView(value: progress)
            .tint(source.tint)
        }

        Button(buttonTitle) {
          if phase == .complete {
            dismiss()
          } else if phase == .failed {
            phase = .ready
          } else {
            start(archiveCount: 1)
          }
        }
        .buttonStyle(.borderedProminent)
        .tint(source.tint)
        .disabled(phase == .importing)

        if source == .youtube && phase == .ready {
          Button("Build multi-part archive queue") {
            showsQueueBuilder = true
          }
          .buttonStyle(.bordered)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(24)
      .background(palette.groupedBackground)
      .navigationTitle(source.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(
        palette.groupedBackground,
        for: .navigationBar
      )
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            dismiss()
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          if phase == .ready {
            Button("Test error") {
              phase = .failed
            }
          }
        }
      }
      .sheet(isPresented: $showsQueueBuilder) {
        DemoImportQueueBuilder(queue: $queue) {
          start(archiveCount: queue.count)
        }
      }
    }
    .preferredColorScheme(session.preferences.colorScheme)
    .presentationDetents([.medium])
  }

  private var title: String {
    switch phase {
    case .ready:
      return "Choose a mock archive"
    case .importing:
      return "Importing locally"
    case .complete:
      return "Import complete"
    case .failed:
      return "Archive could not be read"
    }
  }

  private var message: String {
    switch phase {
    case .ready:
      return "No file is read. The flow simulates a valid \(source.shortName) archive."
    case .importing:
      return "Restoring subscriptions, playlists, history, and watch progress."
    case .complete:
      return "\(importedArchiveCount) archive(s): 42 subscriptions, 6 playlists, and 128 history entries restored."
    case .failed:
      return "The mock archive is invalid. Retry with the sample or rebuild the queue."
    }
  }

  private var buttonTitle: String {
    switch phase {
    case .complete:
      return "Done"
    case .failed:
      return "Retry"
    default:
      return "Use sample archive"
    }
  }

  private var statusSymbol: String {
    switch phase {
    case .complete:
      return "checkmark.circle.fill"
    case .failed:
      return "exclamationmark.triangle.fill"
    default:
      return source.systemImage
    }
  }

  private func start(archiveCount: Int) {
    importedArchiveCount = max(1, archiveCount)
    progress = 0
    phase = .importing
    Task { @MainActor in
      for step in 1...10 {
        try? await Task.sleep(for: .milliseconds(130))
        progress = Double(step) / 10
      }
      session.applyMockImport(from: source)
      phase = .complete
    }
  }
}
