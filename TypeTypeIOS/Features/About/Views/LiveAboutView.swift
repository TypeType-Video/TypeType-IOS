import SwiftUI

struct LiveAboutView: View {
  @ObservedObject var coordinator: RootCoordinator
  let versionService: LiveVersionServiceProtocol
  @State private var versions: LiveComponentVersions?
  @State private var isLoadingVersions = false
  @State private var pendingURL: URL?

  init(
    coordinator: RootCoordinator,
    versionService: LiveVersionServiceProtocol
  ) {
    self.coordinator = coordinator
    self.versionService = versionService
  }

  var body: some View {
    List {
      header
      applicationSection
      licensesSection
      versionsSection
      if coordinator.selectedServer != nil {
        serverSection
      }
    }
      .id(DemoTheme.renderToken)
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(DemoTheme.background)
    .navigationTitle("About")
    .navigationBarTitleDisplayMode(.inline)
    .externalLinkAlert(pendingURL: $pendingURL)
    .task {
      await refreshVersions()
      await coordinator.refreshCurrentUser()
    }
    .refreshable { await refreshVersions() }
  }

  private var header: some View {
    Section {
      VStack(spacing: 14) {
        Image("TypeTypeLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 88, height: 88)
        Text("TypeType")
          .font(.title.weight(.bold))
        Text(appVersion)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 18)
    }
  }

  private var applicationSection: some View {
    Section {
      LabeledContent("Name", value: "TypeType")
      LabeledContent("Version", value: appVersion)
      LabeledContent("License", value: "MPL 2.0")
    } header: { Text("Application").liveSectionHeader() }
  }

  private var licensesSection: some View {
    Section {
      externalLink(
        "TypeType on GitHub",
        symbol: "chevron.left.forwardslash.chevron.right",
        urlString: "https://github.com/TypeType-Video"
      )
      externalLink(
        "PipePipe",
        symbol: "play.rectangle",
        urlString: "https://github.com/InfinityLoop1308/PipePipe"
      )
      externalLink(
        "Support TypeType",
        symbol: "heart.fill",
        urlString: "https://github.com/sponsors/Priveetee"
      )
    } header: { Text("Open source").liveSectionHeader() } footer: {
      VStack(alignment: .leading, spacing: 4) {
        Text("Third-party notice")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(DemoTheme.accent)
        Text(
          "Appearance and theme patterns are inspired by Komi Store, licensed under Apache-2.0."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        Link(
          "Komi Store",
          destination: URL(
            string: "https://github.com/kurikomi-labs/komi-store"
          )!
        )
        .font(.caption.weight(.medium))
        .foregroundStyle(DemoTheme.accent)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 8)
    }
  }

  @ViewBuilder
  private var versionsSection: some View {
    Section {
      if let versions {
        versionRow("Frontend", versions.frontend)
        versionRow("Server", versions.server)
        versionRow("Token", versions.token)
        versionRow("Downloader", versions.downloader)
      } else if isLoadingVersions {
        HStack {
          Text("Loading versions")
          Spacer()
          ProgressView()
        }
      } else {
        Text("Component versions are unavailable.")
          .foregroundStyle(.secondary)
      }
    } header: { Text("Versions").liveSectionHeader() } footer: {
      Button("Refresh versions") {
        Task { await refreshVersions() }
      }
    }
  }

  @ViewBuilder
  private var serverSection: some View {
    Section {
      LabeledContent(
        "URL",
        value: coordinator.selectedServer?.baseURLString
          .removingSuffix("/")
          .removingSuffix("/api") ?? ""
      )
      if let user = coordinator.currentUser {
        LabeledContent(
          "Signed in as",
          value: user.publicUsername ?? user.id
        )
        LabeledContent(
          "Role",
          value: user.role.rawValue.capitalized
        )
      }
    } header: { Text("Server").liveSectionHeader() }
  }

  private func versionRow(
    _ title: String,
    _ version: LiveComponentVersion?
  ) -> some View {
    LabeledContent(
      title,
      value: version?.version ?? "Unavailable"
    )
  }

  private func externalLink(
    _ title: String,
    symbol: String,
    urlString: String
  ) -> some View {
    Button {
      pendingURL = URL(string: urlString)
    } label: {
      Label(title, systemImage: symbol)
    }
  }

  private var appVersion: String {
    let short = Bundle.main.object(
      forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as? String ?? "0.0"
    let build = Bundle.main.object(
      forInfoDictionaryKey: "CFBundleVersion"
    ) as? String ?? "1"
    return "\(short) (\(build))"
  }

  private func refreshVersions() async {
    isLoadingVersions = true
    defer { isLoadingVersions = false }
    versions = try? await versionService.fetchVersions()
  }
}

private extension String {
  func removingSuffix(_ suffix: String) -> String {
    hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
  }
}
