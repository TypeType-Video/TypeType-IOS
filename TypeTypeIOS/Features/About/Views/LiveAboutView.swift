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
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header
        applicationSection
        licensesSection
        versionsSection
        if coordinator.selectedServer != nil {
          serverSection
        }
      }
      .padding(.vertical, 16)
    }
    .background(DemoTheme.pageBackground)
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
    .padding(.vertical, 8)
  }

  private var applicationSection: some View {
    section("Application") {
      LiveSettingsRow(title: "Name") { Text("TypeType") }
      LiveSettingsDivider()
      LiveSettingsRow(title: "Version") { Text(appVersion) }
      LiveSettingsDivider()
      LiveSettingsRow(title: "License") { Text("MPL 2.0") }
    }
  }

  private var licensesSection: some View {
    section("Open source") {
      externalLink(
        "TypeType on GitHub",
        symbol: "chevron.left.forwardslash.chevron.right",
        urlString: "https://github.com/TypeType-Video"
      )
      LiveSettingsDivider()
      externalLink(
        "PipePipe",
        symbol: "play.rectangle",
        urlString: "https://github.com/InfinityLoop1308/PipePipe"
      )
      LiveSettingsDivider()
      externalLink(
        "Support TypeType",
        symbol: "heart.fill",
        urlString: "https://github.com/sponsors/Priveetee"
      )
    } footer: {
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
      .padding(.horizontal, 20)
      .padding(.top, 12)
    }
  }

  @ViewBuilder
  private var versionsSection: some View {
    section("Versions") {
      if let versions {
        versionRow("Frontend", versions.frontend)
        LiveSettingsDivider()
        versionRow("Server", versions.server)
        LiveSettingsDivider()
        versionRow("Token", versions.token)
        LiveSettingsDivider()
        versionRow("Downloader", versions.downloader)
      } else if isLoadingVersions {
        HStack {
          Text("Loading versions")
          Spacer()
          ProgressView()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
      } else {
        Text("Component versions are unavailable.")
          .foregroundStyle(.secondary)
          .padding(.horizontal, 20)
          .padding(.vertical, 12)
      }
    } footer: {
      Button("Refresh versions") {
        Task { await refreshVersions() }
      }
      .buttonStyle(.plain)
      .foregroundStyle(DemoTheme.accent)
      .font(.subheadline.weight(.medium))
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.top, 12)
    }
  }

  @ViewBuilder
  private var serverSection: some View {
    section("Server") {
      LiveSettingsRow(title: "URL") {
        Text(
          coordinator.selectedServer?.baseURLString
            .removingSuffix("/")
            .removingSuffix("/api") ?? ""
        )
      }
      if let user = coordinator.currentUser {
        LiveSettingsDivider()
        LiveSettingsRow(title: "Signed in as") {
          Text(user.publicUsername ?? user.id)
        }
        LiveSettingsDivider()
        LiveSettingsRow(title: "Role") {
          Text(user.role.rawValue.capitalized)
        }
      }
    }
  }

  private func section<Content: View, Footer: View>(
    _ title: String,
    @ViewBuilder content: () -> Content,
    @ViewBuilder footer: () -> Footer = { EmptyView() }
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title)
        .liveSectionHeader()
        .padding(.horizontal, 20)
      LiveSettingsCard(content: content)
      footer()
    }
  }

  private func versionRow(
    _ title: String,
    _ version: LiveComponentVersion?
  ) -> some View {
    LiveSettingsRow(title: title) {
      Text(version?.version ?? "Unavailable")
    }
  }

  private func externalLink(
    _ title: String,
    symbol: String,
    urlString: String
  ) -> some View {
    Button {
      pendingURL = URL(string: urlString)
    } label: {
      HStack(spacing: 16) {
        Image(systemName: symbol)
          .frame(width: 24)
        Text(title)
        Spacer()
      }
      .foregroundStyle(DemoTheme.accent)
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .frame(minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
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
