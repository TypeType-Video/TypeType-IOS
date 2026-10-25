import SwiftUI

struct LiveYouTubeSessionView: View {
  let baseURL: URL?
  let remoteLoginEnabled: Bool
  @StateObject private var viewModel: LiveYouTubeSessionViewModel
  @StateObject private var browser = LiveYouTubeRemoteBrowser()

  init(
    baseURL: URL?,
    remoteLoginEnabled: Bool,
    service: LiveYouTubeSessionServiceProtocol
  ) {
    self.baseURL = baseURL
    self.remoteLoginEnabled = remoteLoginEnabled
    _viewModel = StateObject(
      wrappedValue: LiveYouTubeSessionViewModel(service: service)
    )
  }

  var body: some View {
    Form {
      Section {
        LabeledContent(
          "YouTube",
          value: viewModel.status?.status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized ?? "Loading"
        )
        if let updatedAt = viewModel.status?.updatedAt,
          updatedAt > 0 {
          LabeledContent(
            "Updated",
            value: date(updatedAt).formatted(
              date: .abbreviated,
              time: .shortened
            )
          )
        }
      } header: { Text("Status").liveSectionHeader() }

      if viewModel.browserSession != nil {
        Section {
          LiveYouTubeRemoteBrowserView(browser: browser)
          Text("Tap the browser, then use the text field to type.")
            .font(.caption)
            .foregroundStyle(.secondary)
          Button("Cancel sign-in", role: .destructive) {
            browser.sendCancel()
            browser.close()
            Task { await viewModel.cancelBrowser() }
          }
        } header: { Text("Remote sign-in").liveSectionHeader() }
      } else {
        Section {
          Text(
            "TypeType opens a temporary remote browser. Credentials stay between that browser and YouTube."
          )
          .font(.callout)
          Button("Connect with YouTube") {
            Task {
              if let url = await viewModel.start(baseURL: baseURL) {
                browser.connect(to: url)
              }
            }
          }
          .disabled(!remoteLoginEnabled || viewModel.isBusy)
          if !remoteLoginEnabled {
            Text("Remote YouTube login is disabled on this instance.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          if viewModel.status?.isConnected == true {
            Button("Disconnect", role: .destructive) {
              Task { await viewModel.disconnect() }
            }
            .disabled(viewModel.isBusy)
          }
        } header: { Text("Connection").liveSectionHeader() }
      }

      if case let .failed(message) = viewModel.state {
        Section {
          Label(message, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
          Button("Try again") {
            Task { await viewModel.refresh() }
          }
        }
      }
    }
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(DemoTheme.background)
      .id(DemoTheme.renderToken)
    .navigationTitle("YouTube session")
    .navigationBarTitleDisplayMode(.inline)
    .task { await viewModel.prepare() }
    .onChange(of: browser.phase) { _, phase in
      guard phase == .connected else { return }
      browser.close()
      Task { await viewModel.completeBrowser() }
    }
    .onDisappear {
      guard viewModel.browserSession == nil else { return }
      browser.close()
    }
    .accessibilityIdentifier("live.youtube-session")
  }

  private func date(_ milliseconds: Int64) -> Date {
    Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1_000)
  }
}
