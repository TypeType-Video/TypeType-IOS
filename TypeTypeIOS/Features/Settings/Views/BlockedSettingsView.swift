import SwiftUI

struct BlockedSettingsView: View {
  @StateObject private var viewModel: BlockedSettingsViewModel

  init(service: BlockedServiceProtocol) {
    _viewModel = StateObject(wrappedValue: BlockedSettingsViewModel(service: service))
  }

  var body: some View {
    List {
      if let error = viewModel.errorMessage {
        Section {
          Text(error)
            .font(.footnote)
            .foregroundStyle(.red)
        }
      }

      if !viewModel.blockedChannels.isEmpty {
        Section("Blocked channels") {
          ForEach(viewModel.blockedChannels) { item in
            HStack {
              Text(item.name ?? item.url)
                .lineLimit(1)
              Spacer()
              Button("Unblock", role: .destructive) {
                Task { await viewModel.unblockChannel(item) }
              }
              .font(.caption)
            }
          }
        }
      }

      if !viewModel.blockedVideos.isEmpty {
        Section("Blocked videos") {
          ForEach(viewModel.blockedVideos) { item in
            HStack {
              Text(item.url)
                .lineLimit(1)
                .font(.footnote)
              Spacer()
              Button("Unblock", role: .destructive) {
                Task { await viewModel.unblockVideo(item) }
              }
              .font(.caption)
            }
          }
        }
      }

      if viewModel.blockedChannels.isEmpty && viewModel.blockedVideos.isEmpty && !viewModel.isLoading {
        Section {
          Text("No blocked channels or videos.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Blocked")
    .task { await viewModel.load() }
    .refreshable { await viewModel.load() }
  }
}
